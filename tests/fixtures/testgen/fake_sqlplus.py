"""Stand-in for sqlplus in unit tests: reads a script on stdin, prints canned output."""

import sys

script = sys.stdin.read()
if "FAIL_RUN" in script:
    sys.exit(3)
if "ut.run" in script:
    cases = (
        '<testcase classname="t" name="ok"/>'
        '<testcase classname="t" name="bad"><failure message="boom">boom</failure></testcase>'
        '<testcase classname="t" name="err"><error message="ora">ora</error></testcase>'
    )
    print(
        f'<?xml version="1.0"?><testsuites><testsuite name="t" tests="3">{cases}</testsuite></testsuites>'
    )
elif "BROKEN_BODY" in script:
    print("PLL_ERR|PACKAGE BODY|5:3 PLS-00201: identifier 'X' must be declared")
    print("PLL_STATUS|PACKAGE BODY|INVALID")
elif "NO_BODY" in script:
    print("Warning: nothing created")
else:
    print("PLL_STATUS|PACKAGE|VALID")
    print("PLL_STATUS|PACKAGE BODY|VALID")
