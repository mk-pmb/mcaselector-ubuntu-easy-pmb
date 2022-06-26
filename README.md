
<!--#echo json="package.json" key="name" underline="=" -->
mcaselector-ubuntu-easy-pmb
===========================
<!--/#echo -->

<!--#echo json="package.json" key="description" -->
Simplify the installation and invocation of MCA Selector on Ubuntu.
<!--/#echo -->


Install
-------

* Use Ubuntu 20.04 or later.
* Have Java v17 or later installed.
  (The apt package should be `openjdk-17-jdk`.)
* Clone this repo.
* `./easy.sh download`

If you want to download MCA Selector while apt is still busy with
installing Java, you can override the version detection:

```bash
OVERRIDE_JAVA_MAJOR_VERSION=17 ./easy.sh download
```



Usage
-----

```bash
# To start MCA Selector:
./easy.sh
```



Configuration
-------------

Is done via environment variables.
Usually you don't need any of these.

* `CUSTOM_JAVA_LAUNCHER`:
  Which command to use to run Java. Default: `java`
* `OVERRIDE_JAVA_MAJOR_VERSION`:
  Skip version detection and assume this number as the major version of Java.
  "Major" means the first of the dot-separated numbers in your Java version.






<!--#toc stop="scan" -->



Known issues
------------

* Needs more/better tests and docs.




&nbsp;


License
-------
<!--#echo json="package.json" key=".license" -->
ISC
<!--/#echo -->
