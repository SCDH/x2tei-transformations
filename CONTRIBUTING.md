# Contributing

## Rules and Conventions

### Package names

A package's name must be a URI. The name of each package in this
repository is its relative name in this repository prefixed with the
following base URL.

```
https://scdh.zivgitlabpages.uni-muenster.de/tei-processing/x2tei-transformations/
```

For example the name of the package in
`xsl/pagexml/pagecontent2tei.xsl` is
`https://scdh.zivgitlabpages.uni-muenster.de/tei-processing/x2tei-transformations/xsl/pagexml/pagecontent2tei.xsl`.

### Package versions

**Use a primer version like `1.0.0` and keep it untouched through all
your changes. Stay with only one version per package.** The packages
in the repository must be **working set**.

There may be a versioning in future, which will be based on a git tag
and the version from the Maven pom and which will be fully
automatically processed. Even then, the XSLT packages under version
control will keep their single primer version; and only packages in
distributions will get the version tag and only distributions may
contain different versions of the same package. Even in this case, the
primer version will be contained in such a distribution and it will be
functionally equivalent with the package version with the current tag.


### Debugging

For performance reasons, debugging messages should be turned on or off
at compile time, not by a stylesheet parameter. We are using the
following compile time switch throughout the whole project:

```
@use-when="system-property('debug') eq 'true'"
```

To turn on debugging messages add `-Ddebug=true` when running the
program. E.g. for Saxon write:

```{shell}
java -Ddebug=true -jar saxon.jar ...
```
The same command line switch can be used for Oxygen.

The wrapper scripts have debugging turned on by default. Use `1>` and
`2>` to fork output from stdin and stderr.

### Directory structure

- `xsl` container for XSLT, except XSLT for managing this project
- The next subfolder level is the input format.
  - E.g. `xsl/docx` for Word XML files.

### Qualified names and namespaces

**Every component** from a package, that is **accessible from the outside**,
**must** have a **qualified** name! The same holds true for
parameters. This avoids name conflicts.

To set a parameter value, use `{NAMESPACE}LNAME=...` to specify its
qualified name.

This project use `http://scdh.wwu.de/transform/` as a base URI for
namespace names and append an other semantically motivated path
element and a hash tag, like in `http://scdh.wwu.de/transform/docx#`
for components dealing with internationalization.

### Names of templates, functions, variables etc.

Do not duplicate work, that the XSLT compiler does for you! Keep names
of components in the semantic domain.

Examples of bad practise:

1. you declare a tunnel parameter for passing around wine and prefix its name with `tp`: `tpWine`
2. you declare a function for drinking and prefix its name with `fun`: `funDrink`


Instead:

- `wine`
- `drink`

More examples of this bad practise is found in the TEI's current
naming conventions for XSLT, however they are traded under the name of
good practise.

### Types everywhere

Declare the type of every variable, function, parameter!

Stylesheet parameters without declared type are breaking bad. They
break the automatic type conversion of some applications like the SEED
XML Transformer or tools for generating documentation.

Even declare the type of the result set of templates, at least if it's
not a node set!

### No XSLT 1.0

XSLT 1.0 was an untyped language. We do not use it in this
project. Use XSLT 2.0 or later.

### Let the processor descend

XSLT is such an extraordinary language because we do not have to tell
the processor how to descend the XML tree as we have to in other
languages like XQuery with its [`typeswitch`
idiom](https://en.wikibooks.org/wiki/XQuery/Typeswitch_Transformations)
idiom. Let the processor do his job by telling him
`<xsl:apply-templates mode="#current"/>` even if you are quite sure
that there will only a terminal text node you could easily catch with
a select. Just provide the processor some templates with match
conditions.  Also consider substituting branching with `<xsl:choose>`
by writing templates with match conditions.

These rules of thumb are the key to writing transformations that are
*generic*, *reusable* and in particular: *extensible*. Extensible in a
way, no `typeswitch` construction can ever be (unless you replace it
with a higher order construct).

### Avoid `normalize-space()`

Avoid normalizing space. It makes the transformation result
intransparent to its XML source when it comes to annotations. Do not
try to heal spacing errors done by the editors.

### xsl:evaluate

You can use `xsl:evaluate`. However: **Do not pass any content to its
`xpath` input, that can be determined by runtime input** (source,
runtime parameters).

You can write super flexible great code using `xsl:evaluate`. But use
a static variable for determining its xpath input! Override this
variable for project-specific configurations, instead of passing in the
configuration as a runtime parameter.

This rule is for security!

Consider [**abstract
components**](https://www.w3.org/TR/xslt-30/#dt-visibility) as an
alternative!

### Write XSpec tests

Write [XSpec](https://github.com/xspec/xspec/wiki) tests. Learn from
the xspec files in this repository.

Add your tests to the [Ant test runner](build.xml).

Run tests with

```
target/bin/test.sh # all tests
```

```
target/bin/test.sh TARGET-NAME # single test
```

**Every transformation distributed for the SEED XML Transformer must
be tested.** At least is must compile. Otherwise, the REST service
will not pass its health test.


### Register packages

Register new packages in the `saxon.xml` configuration file.



## Pull Requests

Pull requests **will not be accepted**, if they are made on the
default or production branch directly. Use a feature branch!

## Keep changes.md up to date

Report changes in [`changes.md`](changes.md).

## Maven

The [Maven pom file](pom.xml) is the single point of truth in this
project.

It can install everything required for this project.

It knows how to build the various distributions of this project.

### Version Numbers

The single source of truth for version numbers of releases, however,
are git commit tags. Each tag following the pattern
`MAJOR.MINOR.BUGFIX[extra]` results in a release. The pom file gets
the version number through the `${revision}${changelist}` [maven
variables](https://maven.apache.org/maven-ci-friendly.html), which are
set in pipeline jobs that are run on release tags.
