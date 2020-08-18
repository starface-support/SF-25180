# SF-25180
Deploy fixed (`strictrtp`) Asterisk packages


## Invocation

To apply hotfixed Asterisk RPMs run
```bash
curl -sSL https://git.io/JJNLk | /bin/bash
```

Pass parameters to the bash pipe like so:
```bash
curl -sSL https://git.io/JJNLk | /bin/bash -s -- -v
```

### Parameters
* `-d`: Debug mode, run RPM with `--test` parameter.
* `-v`: Verbose. Print more details.
