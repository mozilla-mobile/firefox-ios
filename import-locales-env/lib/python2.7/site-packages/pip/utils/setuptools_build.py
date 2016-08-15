# Shim to wrap setup.py invocation with setuptools
SETUPTOOLS_SHIM = (
    "import setuptools, tokenize;__file__=%r;"
    "exec(compile(getattr(tokenize, 'open', open)(__file__).read()"
    ".replace('\\r\\n', '\\n'), __file__, 'exec'))"
)
