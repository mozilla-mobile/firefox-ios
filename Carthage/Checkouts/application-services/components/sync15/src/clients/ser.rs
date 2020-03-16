/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use std::io::{self, Write};

use serde::Serialize;
use serde_json;

use crate::error::Result;

/// A writer that counts the number of bytes it's asked to write, and discards
/// the data. Used to calculate the serialized size of the commands list.
#[derive(Clone, Copy, Default)]
pub struct WriteCount(usize);

impl WriteCount {
    #[inline]
    pub fn len(self) -> usize {
        self.0
    }
}

impl Write for WriteCount {
    #[inline]
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        self.0 += buf.len();
        Ok(buf.len())
    }

    #[inline]
    fn flush(&mut self) -> io::Result<()> {
        Ok(())
    }
}

/// Returns the size of the given value, in bytes, when serialized to JSON.
fn compute_serialized_size<T: Serialize>(value: &T) -> Result<usize> {
    let mut w = WriteCount::default();
    serde_json::to_writer(&mut w, value)?;
    Ok(w.len())
}

/// Truncates `list` to fit within `payload_size_max_bytes` when serialized to
/// JSON.
pub fn shrink_to_fit<T: Serialize>(list: &mut Vec<T>, payload_size_max_bytes: usize) -> Result<()> {
    let size = compute_serialized_size(&list)?;
    // See bug 535326 comment 8 for an explanation of the estimation
    match ((payload_size_max_bytes / 4) * 3).checked_sub(1500) {
        Some(max_serialized_size) => {
            if size > max_serialized_size {
                // Estimate a little more than the direct fraction to maximize packing
                let cutoff = (list.len() * max_serialized_size - 1) / size + 1;
                list.truncate(cutoff + 1);
                // Keep dropping off the last entry until the data fits.
                while compute_serialized_size(&list)? > max_serialized_size {
                    if list.pop().is_none() {
                        break;
                    }
                }
            }
            Ok(())
        }
        None => {
            list.clear();
            Ok(())
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::clients::record::CommandRecord;

    #[test]
    fn test_compute_serialized_size() {
        assert_eq!(compute_serialized_size(&1).unwrap(), 1);
        assert_eq!(compute_serialized_size(&"hi").unwrap(), 4);
        assert_eq!(
            compute_serialized_size(&["hi", "hello", "bye"]).unwrap(),
            20
        );
    }

    #[test]
    fn test_shrink_to_fit() {
        let mut commands = vec![
            CommandRecord {
                name: "wipeEngine".into(),
                args: vec!["bookmarks".into()],
                flow_id: Some("flow".into()),
            },
            CommandRecord {
                name: "resetEngine".into(),
                args: vec!["history".into()],
                flow_id: Some("flow".into()),
            },
            CommandRecord {
                name: "logout".into(),
                args: Vec::new(),
                flow_id: None,
            },
        ];

        // 4096 bytes is enough to fit all three commands.
        shrink_to_fit(&mut commands, 4096).unwrap();
        assert_eq!(commands.len(), 3);

        let sizes = commands
            .iter()
            .map(|c| compute_serialized_size(c).unwrap())
            .collect::<Vec<_>>();
        assert_eq!(sizes, &[61, 60, 30]);

        // `logout` won't fit within 2168 bytes.
        shrink_to_fit(&mut commands, 2168).unwrap();
        assert_eq!(commands.len(), 2);

        // `resetEngine` won't fit within 2084 bytes.
        shrink_to_fit(&mut commands, 2084).unwrap();
        assert_eq!(commands.len(), 1);

        // `wipeEngine` won't fit at all.
        shrink_to_fit(&mut commands, 1024).unwrap();
        assert!(commands.is_empty());
    }
}
