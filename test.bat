@echo off
rem Скрипт для экспорта данных используя MultiSite Collaboration
rem Запускать из коммандной строки, предварительно корректно
rem установив переменные IMAN_ROOT и IMAN_DATA. Скрипт принимает 3 параметра,
rem два первых обязательны, третий не обязателен. Первый параметр задает   
rem путь к файлу со списком ID, которые должны быть переданы. Второй параметр
rem задает имя сайта, на который данные должны быть переданы. Третий, не 
rem обязательный параметр, если он есть и равен значению transfer, то экспорт
rem будет произведен с передачей прав владения, иначе без передачи прав.
rem Особенности:
rem -скрипт состоит из одного файла
rem -скрипт сайтонезависим, то есть он будет правильно работать на всех сайтах
rem -скрипт запрашивает пароль infodba, так что его не надо хранить в нем
rem -скрипт проверяет корректность указанного сайта
rem -скрипт отображает количество выполненных деталей
if NOT EXIST "%IMAN_DATA%" goto :iman_error
if NOT EXIST "%IMAN_ROOT%" goto :iman_error
if !%1==! goto :help
IF !%2==!  goto :help
set FILENAME=%1
set SITENAME=%2
rem Если TRANSFER=0 то без передачи прав, иначе с передачей
set TRANSFER=0
IF !%3==!  goto :start 
rem Если третий параметр существует и он = transfer, то значение TRANSFER=1
if %3==transfer (
set TRANSFER=1
rem cls 
rem color 0c
rem echo Export with TRANSFER!!!
rem set /p answer=Confirm? [y/n]
rem if %answer%==n  ( goto :ENDOFFILE )
)
)
color 0f
:start
if NOT EXIST "%FILENAME%" goto :file_error
rem ####################################################
rem Инициализируем переменные окружения
call %IMAN_DATA%\iman_profilevars
rem Получаем список сайтов и заносим их во временный файл
site_util -f=list > %TEMP%\list.txt
set RESIF=0
rem Разбор временного файла
for /F "usebackq tokens=2 skip=2" %%i in (%TEMP%\list.txt) DO if %SITENAME%==%%i set RESIF=1
rem Если сайт не найден то выводим сообщение об этом
if %RESIF%==0 goto :site_error 
echo List of imported Items > %~dp1\imported.txt
echo List of ERROR Items > %~dp1\error.txt
set report_name=%~dp1\report.log
echo REPORT > %report_name%
echo DATE >> %report_name%
date /T >> %report_name%
echo TIME >> %report_name%
time /T >> %report_name%
set /a a=0
rem echo Enter password for infodba:
set /p "passwd=Enter password for infodba: "
set /a count=0
for /F %%j in (%1) do set /a count+=1
set /a current=0
set /a err=0
setlocal enabledelayedexpansion
for /F %%i in (%1) DO (
set /a current+=1
echo ========================================================================== >> %report_name%
echo Report for %%i >> %report_name%
echo %%i [!current!/!count!]
if !TRANSFER!==1 (
data_share -u=infodba -p="%passwd%" -g=dba -f=send -transfer -site=%SITENAME% -item_id=%%i -exlude=IMAN_based_on -exclude=IMAN_UG_expression -exclude=IMAN_MEAppearance -exclude=IMAN_UG_promotion -exclude=IMAN_UG_wave_position -exclude=IMAN_UG_wave_part_link -exclude=IMAN_UG_wave_geometry > %~dp1\stdout
) else (
data_share -u=infodba -p="%passwd%" -g=dba -f=send -site=%SITENAME% -item_id=%%i -exlude=IMAN_based_on -exclude=IMAN_UG_expression -exclude=IMAN_MEAppearance -exclude=IMAN_UG_promotion -exclude=IMAN_UG_wave_position -exclude=IMAN_UG_wave_part_link -exclude=IMAN_UG_wave_geometry > %~dp1\stdout
)
findstr /M "success" %~dp1\stdout > %~dp1\finded 
if !ERRORLEVEL! == 0 (
rem NO Error
set ERORRLEVEL=0
echo %%i >> %~dp1\imported.txt
echo success
) else (
rem ERROR
set /a err+=1
set ERORRLEVEL=0
echo %%i >> %~dp1\error.txt
echo error  [!err!]
)
type %~dp1\stdout >> %report_name%
)
del %~dp1\finded
del %~dp1\stdout
rem ####################################################
goto :ENDOFFILE
 
:help
echo Usage: %~n0 file_name site [transfer]
pause
goto :ENDOFFILE
 
:site_error
echo Site %SITENAME% not found!
pause
goto :ENDOFFILE
 
:file_error
echo %FILENAME% not exist
pause
goto :ENDOFFILE
 
:iman_error
echo IMAN_DATA and IMAN_ROOT must be set
pause
goto :ENDOFFILE
 
:ENDOFFILE
color 0f
@echo on
