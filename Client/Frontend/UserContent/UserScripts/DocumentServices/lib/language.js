import guessLanguage from 'franc';
import { by639_2T } from 'iso-language-codes';

// franc has some excentricities, in reporting CN and ARA.
// so we have to correct for them. There may be more.
const corrector = {
  cmn: "zho",
  arb: "ara",
};

module.exports = function (metadata) {
  const text = metadata['description'];
  if (!text) {
    return;
  }
  const guess = guessLanguage(text);
  const isoCode = corrector[guess] || guess

  return by639_2T[isoCode];
};
