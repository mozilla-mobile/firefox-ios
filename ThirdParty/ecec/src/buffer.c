#include "ece.h"

// This file implements a buffer data type. Each buffer is backed by a byte
// array, and knows its own length. By convention, functions take buffers as
// `const` in parameters. It's safe for the caller to free the buffer after
// the function returns. Functions that take buffers as out parameters will
// reset the buffer; it's not necessary to call `ece_buf_reset` beforehand.
// Freeing a buffer resets it, so it's safe to call `ece_buf_free` multiple
// times on the same buffer. This simplifies error handling paths. It's also
// possible to take a slice of an existing buffer. However, since all slices
// share the same backing array, it's not safe for a slice to outlive its
// parent, or to free a slice.

#include <assert.h>
#include <stdlib.h>

bool
ece_buf_alloc(ece_buf_t* buf, size_t len) {
  assert(!buf->bytes && !buf->length);
  buf->bytes = (uint8_t*) malloc(len * sizeof(uint8_t));
  buf->length = buf->bytes ? len : 0;
  return buf->length;
}

void
ece_buf_slice(const ece_buf_t* buf, size_t start, size_t end,
              ece_buf_t* slice) {
  slice->bytes = &buf->bytes[start];
  slice->length = end - start;
}

void
ece_buf_reset(ece_buf_t* buf) {
  buf->bytes = NULL;
  buf->length = 0;
}

void
ece_buf_free(ece_buf_t* buf) {
  free(buf->bytes);
  ece_buf_reset(buf);
}
