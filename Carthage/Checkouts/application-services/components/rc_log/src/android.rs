/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//! This is the android backend for rc_log. It has a decent amount of
//! complexity, as Rust logs can be emitted by any thread, regardless of whether
//! or not they have an associated JVM thread. JNA's Callback class helps us
//! here, by providing a way for mapping native threads to JVM threads.
//! Unfortunately, naive usage of this class in a multithreaded context will be
//! very suboptimal in terms of memory and thread usage.
//!
//! To avoid this, we only call into the JVM from a single thread, which we
//! launch when initializing the logger. This thread just polls a channel
//! listening for log messages, where a log message is an enum (`LogMessage`)
//! that either tells it to log an item, or to stop logging all together.
//!
//! 1. We cannot guarantee that the callback from android lives past when the
//!    android code tells us to stop logging, so in order to be memory safe, we
//!    need to stop logging immediately when this happens. We do this using an
//!    `Arc<AtomicBool>`, used to indicate that we should stop logging.
//!
//! 2. There's no safe way to terminate a thread in Rust (for good reason), so
//!    the background thread must close willingly. To make sure this happens
//!    promptly (e.g. to avoid a case where we're blocked until some thread
//!    somewhere else happens to log something), we need to add something onto
//!    the log channel, hence the existence of `LogMessage::Stop`.
//!
//!    It's important to note that because of point 1, the polling thread may
//!    have to stop prior to getting `LogMessage::Stop`. We do not want to wait
//!    for it to process whatever log messages were sent prior to being told to
//!    stop.

use std::{
    ffi::CString,
    os::raw::c_char,
    sync::{
        atomic::{AtomicBool, Ordering},
        mpsc::{sync_channel, SyncSender},
        Arc, Mutex,
    },
    thread,
};

use crate::LogLevel;

/// Type of the log callback provided to us by java/swift. Takes the following
/// arguments:
///
/// - Log level (an i32).
///
/// - Tag: a (nullable) nul terminated c string. The callback must not free this
///   string, which is only valid until the the callback returns. If you need
///   it past that, you must copy it into an internal buffer!
///
/// - Message: a (non-nullable) nul terminated c string. The callback must not free this
///   string, which is only valid until the the callback returns. If you need
///   it past that, you must copy it into an internal buffer!
///
/// and returns 0 if we should close the thread, and 1 otherwise. This is done
/// because attempting to call `disable` from within the log callback will
/// deadlock.
pub type LogCallback = unsafe extern "C" fn(i32, *const c_char, *const c_char) -> u8;

// TODO: use serde to send this to the other thread as bincode or something,
// rather than allocating all these strings for every message.
struct LogRecord {
    level: LogLevel,
    tag: Option<CString>,
    message: CString,
}

impl<'a, 'b> From<&'b log::Record<'a>> for LogRecord {
    // XXX important! Don't log in this function!
    fn from(r: &'b log::Record<'a>) -> Self {
        let thread_id = format!("{:?}", std::thread::current().id());
        let thread_id = if thread_id.starts_with("ThreadId(") && thread_id.ends_with(')') {
            format!("t{}", &thread_id[9..(thread_id.len() - 1)])
        } else {
            thread_id
        };
        let message = format!("{} {}", thread_id, r.args());
        Self {
            level: r.level().into(),
            tag: r
                .module_path()
                .and_then(|mp| CString::new(mp.to_owned()).ok()),
            message: crate::string_to_cstring_lossy(message),
        }
    }
}

enum LogMessage {
    Stop,
    Record(LogRecord),
}

pub struct LogAdapterState {
    // Thread handle for the BG thread.
    handle: Option<std::thread::JoinHandle<()>>,
    stopped: Arc<Mutex<bool>>,
    sender: SyncSender<LogMessage>,
}

pub struct LogSink {
    sender: SyncSender<LogMessage>,
    // Used locally for preventing unnecessary work after the `sender`
    // is closed. Not shared. Not required for correctness.
    disabled: AtomicBool,
}

impl log::Log for LogSink {
    fn enabled(&self, _metadata: &log::Metadata<'_>) -> bool {
        // Really this could just be Acquire but whatever
        !self.disabled.load(Ordering::SeqCst)
    }

    fn flush(&self) {}
    fn log(&self, record: &log::Record<'_>) {
        // Important: we check stopped before writing, which means
        // it must be set before
        if self.disabled.load(Ordering::SeqCst) {
            // Note: `enabled` is not automatically called.
            return;
        }
        // Either the queue is full, or the receiver is closed.
        // In either case, we want to stop all logging immediately.
        if self
            .sender
            .try_send(LogMessage::Record(record.into()))
            .is_err()
        {
            self.disabled.store(true, Ordering::SeqCst);
        }
    }
}

impl LogAdapterState {
    #[allow(clippy::mutex_atomic)]
    pub fn init(callback: LogCallback) -> Self {
        // This uses a mutex (instead of an atomic bool) to avoid a race condition
        // where `stopped` gets set by another thread between when we read it and
        // when we call the callback. This way, they'll block.
        let stopped = Arc::new(Mutex::new(false));
        let (message_sender, message_recv) = sync_channel(4096);
        let handle = {
            let stopped = stopped.clone();
            thread::spawn(move || {
                // We stop if we see `Err` (which means the channel got closed,
                // which probably can't happen since the sender owned by the
                // logger will never get dropped), or if we get `LogMessage::Stop`,
                // which means we should stop processing.
                while let Ok(LogMessage::Record(record)) = message_recv.recv() {
                    let LogRecord {
                        tag,
                        level,
                        message,
                    } = record;
                    let tag_ptr = tag
                        .as_ref()
                        .map(|s| s.as_ptr())
                        .unwrap_or_else(std::ptr::null);
                    let msg_ptr = message.as_ptr();

                    let mut stop_guard = stopped.lock().unwrap();
                    if *stop_guard {
                        return;
                    }
                    let keep_going = unsafe { callback(level as i32, tag_ptr, msg_ptr) };
                    if keep_going == 0 {
                        *stop_guard = true;
                        return;
                    }
                }
            })
        };

        let sink = LogSink {
            sender: message_sender.clone(),
            disabled: AtomicBool::new(false),
        };

        crate::settable_log::set_logger(Box::new(sink));
        log::set_max_level(log::LevelFilter::Debug);
        log::info!("rc_log adapter initialized!");
        Self {
            handle: Some(handle),
            stopped,
            sender: message_sender,
        }
    }
}

impl Drop for LogAdapterState {
    fn drop(&mut self) {
        {
            // It would be nice to write a log that says something like
            // "if we deadlock here it's because you tried to close the
            // log adapter from within the log callback", but, well, we
            // can't exactly log anything from here (and even if we could,
            // they'd never see it if they hit that situation)
            let mut stop_guard = self.stopped.lock().unwrap();
            *stop_guard = true;
            // We can ignore a failure here because it means either
            // - The recv is dropped, in which case we don't need to send anything
            // - The recv is completely full, in which case it will see the flag we
            //   wrote into `stop_guard` soon enough anyway.
            let _ = self.sender.try_send(LogMessage::Stop);
        }
        // Wait for the calling thread to stop. This should be relatively
        // quickly unless something terrible has happened.
        if let Some(h) = self.handle.take() {
            h.join().unwrap();
        }
    }
}

ffi_support::implement_into_ffi_by_pointer!(LogAdapterState);
