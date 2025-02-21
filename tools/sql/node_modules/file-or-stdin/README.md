# file-or-stdin

[![NPM version](https://img.shields.io/npm/v/file-or-stdin.svg)](https://www.npmjs.com/package/file-or-stdin)
[![Build Status](https://travis-ci.org/shinnn/file-or-stdin.svg?branch=master)](https://travis-ci.org/shinnn/file-or-stdin)
[![Coverage Status](https://img.shields.io/coveralls/shinnn/file-or-stdin.svg)](https://coveralls.io/github/shinnn/file-or-stdin?branch=master)
[![dependencies Status](https://david-dm.org/shinnn/file-or-stdin/status.svg)](https://david-dm.org/shinnn/file-or-stdin)
[![devDependencies Status](https://david-dm.org/shinnn/file-or-stdin/dev-status.svg)](https://david-dm.org/shinnn/file-or-stdin?type=dev)

Read a file, or read stdin if no files are specified

```javascript
// echo "Hello!" | node example.js
const fileOrStdin = require('file-or-stdin');

fileOrStdin('path/to/a/file').then(data => {
  data.toString(); // file contents 
});

sfileOrStdin(null).then(data => {
  data.toString(); //=> 'Hello!'
});
```

## Installation

[Use npm.](https://docs.npmjs.com/cli/install)

```
npm install file-or-stdin
```

## API

```javascript
const fileOrStdin = require('file-or-stdin');
```

### fileOrStdin(*filePath* [, *options*])

*filePath*: `String` or a falsy value  
*options*: `Object` ([`fs.readFile`](https://nodejs.org/api/fs.html#fs_fs_readfile_file_options_callback) options) or `String` (encoding)   
Return: [`Promise`](https://promisesaplus.com/)

When the first argument is a file path, it reads the given file and returns a promise of the file contents.

When the first argument is a falsy value, it reads [stdin](http://www.linfo.org/standard_input.html) and returns a promise of the buffered stdin data.

```javascript
// echo "nodejs" | node example.js
fileOrStdin('', 'utf8').then(data => {
  data; //=> 'nodejs'
});
```

```javascript
// echo "nodejs" | node example.js
fileOrStdin('', 'base64').then(data => {
  data; //=> 'bm9kZWpz'
});
```

## License

Copyright (c) 2016 [Shinnosuke Watanabe](https://github.com/shinnn)

Licensed under [the MIT License](./LICENSE).
