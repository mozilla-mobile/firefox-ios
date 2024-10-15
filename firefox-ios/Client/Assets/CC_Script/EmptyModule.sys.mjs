// This function will create a proxy for each undefined property
// This is useful when the accessed property name is unkonwn beforehand
const undefinedProxy = () =>
  new Proxy(() => {}, {
    get() {
      return undefinedProxy();
    },
  });
export default undefinedProxy();
