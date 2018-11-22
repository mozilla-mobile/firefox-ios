import { ffi } from './__firefox__';
import language from '../lib/language'

function echo (arg) {
  return arg['description'];
}

const analysers = {
  language,
  text: echo,
};

ffi('analyze', function (metadata) {
  const results = {};

  for (let [key, f] of Object.entries(analysers)) {
    const value = f(metadata);

    if (value) {
      results[key] = value;
    }
  }

  return results;
});