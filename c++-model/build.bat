@echo off
REM Build script for QuadraTb on Windows using Visual Studio compiler
REM Replaces Makefile functionality

setlocal enabledelayedexpansion

set CXX=cl.exe
set CXXFLAGS=/std:c++17 /EHsc /O2
set INCS=/IC:\Users\kalem\Downloads\arturkalemaintelinterviewjr0280560aigpuhwipd\libs\ac_types\include
set LIBS=
set DEFS=/DDBG_OUT=1 /DDBG_TST=1

echo Compiling Quadra.cpp...
%CXX% %CXXFLAGS% %DEFS% %INCS% /Fo:Quadra.obj /c Quadra.cpp
if errorlevel 1 (
    echo Compilation of Quadra.cpp failed!
    exit /b 1
)

echo Compiling QuadraTb.cpp...
%CXX% %CXXFLAGS% %DEFS% %INCS% /Fo:QuadraTb.obj /c QuadraTb.cpp
if errorlevel 1 (
    echo Compilation of QuadraTb.cpp failed!
    exit /b 1
)

echo Linking...
%CXX% /Fe:QuadraTb.exe Quadra.obj QuadraTb.obj %LIBS%
if errorlevel 1 (
    echo Linking failed!
    exit /b 1
)

echo.
echo Build successful!
echo.
echo Running QuadraTb.exe...
QuadraTb.exe
pause

