### About

`orgleaks` is a tool to run `gitleaks` for an organization. After version 7 of gitleaks the `--org` parameter was no longer supported. This small shell script helps you perform scans on an organization as well as allows you to pass arguments to gitleaks. 

There is a gitleaks.toml file included in this repo, if you are too lazy to write your own.

***Please note**: This is not a full git scanning / secret scanner, to use this script you require [gitleaks](https://github.com/zricethezav/gitleaks) to be installed.*

### Installation

Make sure you have installed [gitleaks](https://github.com/zricethezav/gitleaks/releases), then:

```
git clone https://github.com/thecybermafia/orgleaks.git
```
Please make sure you have updated your access token or placed an environment variable for the same inside the script, I would recommend you not to hardcode your access token. 

You have to enter your env variable in the place of "youraccesstokengoeshere". Refer to [this guide](https://www.digitalocean.com/community/tutorials/how-to-read-and-set-environmental-and-shell-variables-on-linux) related to creating env variables.

If you are not aware about access tokens, refer to [this documentation](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token) given by Github.

### Usage

```
                         .__                 __             
     ___________  ____   |  |   ____ _____  |  | __  ______ 
    /  _ \_  __ \/ ___\  |  | _/ __ \\__  \ |  |/ / /  ___/ 
   (  <_> )  | \/ /_/  > |  |_\  ___/ / __ \|    <  \___ \  
    \____/|__|  \___  /  |____/\___  >____  /__|_ \/____  > 
               /_____/             \/     \/     \/     \/  
  

  orgleaks.sh ver. 0.1
  To run gitleaks for an organization

  Usage: orgleaks.sh [-h|--help] [-o|--org github] [-v] [-a|--gitleaks-args]

  Options:
  -h, --help  Display this help message and exit.
  -o, --org github  Organization Name
      where 'github' is the Organization Name.
  -s, --save-file orgleaks_report_github
      where 'orgleaks_report_github' is the Report Name.
  -f, --format csv
      where 'csv' is the Report Format.
  -v  verbose
  -a, --gitleaks-args "--config-path=gitleaks.toml"
      where '"--config-path=gitleaks.toml"' are the arguments for Gitleaks
      refer to https://github.com/zricethezav/gitleaks/wiki/Scanning

  Examples:

  orgleaks.sh -o github
  Scans the 'github' organization

  orgleaks.sh -o github -v 
  Scans the 'github' organization and enables verbosity for gitleaks

  orgleaks.sh -o github -v -a "--config-path=gitleaks.toml"
  Scans the 'github' organization, enables verbosity and uses a configuration file

  orgleaks.sh -o github -v -a "--config-path=gitleaks.toml" --save-file orgleaks_report_github --format csv
  Scans the 'github' organization, enables verbosity, uses a configuration file and saves the report in csv format with provided name
  
```

### License

[Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0)
