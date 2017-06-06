del /S /Q _Ignore\release\UCR
mkdir _Ignore\release\UCR
copy UCR.exe _Ignore\release\UCR
copy UCR*.ahk _Ignore\release\UCR
copy CLI.ahk _Ignore\release\UCR
copy msvcr100.dll _Ignore\release\UCR
copy Changelog.txt _Ignore\release\UCR
xcopy /E /I Classes _Ignore\release\UCR\Classes
xcopy /E /I Functions _Ignore\release\UCR\Functions
xcopy /E /I Libraries _Ignore\release\UCR\Libraries
mkdir _Ignore\release\UCR\Plugins
mkdir _Ignore\release\UCR\Plugins\Core
mkdir _Ignore\release\UCR\Plugins\User
xcopy /E /I Plugins\Core _Ignore\release\UCR\Plugins\Core
xcopy /E /I Resources _Ignore\release\UCR\Resources
xcopy /E /I Threads _Ignore\release\UCR\Threads
