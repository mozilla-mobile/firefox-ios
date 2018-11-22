import guessLanguage from 'franc';
import { by639_2T } from 'iso-language-codes';

module.exports = function (metadata) {
  const text = metadata['description'];
  if (!text) {
    return;
  }
  const guess = guessLanguage(text);

  return by639_2T[guess];
};
