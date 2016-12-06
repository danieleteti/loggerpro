import subprocess
import os
from datetime import datetime
from colorama import *
init() #colorama initialization

### task setup env
DOIT_CONFIG = {'verbosity': 2, 'default_tasks': ['build']}

###############################################################################################
############## CONFIGURATION ##################################################################
###############################################################################################
projects = [
			'samples\\01_global_logger\\global_logger.dproj',
			'samples\\02_file_appender\\file_appender.dproj',
			'samples\\03_console_appender\\console_appender.dproj',
			'samples\\04_outputdebugstring_appender\\outputdebugstring_appender.dproj',
			'samples\\05_vcl_appenders\\memo_appender.dproj',
			'samples\\10_multiple_appenders\\multiple_appenders.dproj',
			'samples\\15_appenders_with_different_log_levels\\multi_appenders_different_loglevels.dproj',
			'samples\\20_multiple_loggers\\multiple_loggers.dproj',
			'samples\\50_custom_appender\\custom_appender.dproj',
			'samples\\60_logging_inside_dll\\MainProgram.dproj',
			'samples\\60_logging_inside_dll\\mydll.dproj',
			'samples\\90_remote_logging_with_redis\\RemoteRedisAppenderSample.dproj',
			'samples\\90_remote_logging_with_redis\\redis_logs_viewer\\RedisLogsViewer.dproj'
]

release_path = "BUILD"
###############################################################################################
############## END CONFIGURATION ##############################################################
###############################################################################################

GlobalBuildVersion = 'DEV' #if we are building an actual release, this will be replaced

def header(headers):    
    elements = None
    if type(headers).__name__ == 'str':
        elements = [headers]
    else:
        elements = headers

    print(Style.BRIGHT + Back.WHITE + Fore.RED + "*" * 80 + Style.RESET_ALL)
    for txt in elements:
        s = '{:^80}'.format(txt)
        print(Style.BRIGHT + Back.WHITE + Fore.RED + s + Style.RESET_ALL)       
    print(Style.BRIGHT + Back.WHITE + Fore.RED + "*" * 80 + Style.RESET_ALL)        
    

def buildProject(project, config = 'DEBUG'):
    header(["Building", project,"(config " + config + ")"])
    p = project.replace('.dproj', '.cfg')
    if os.path.isfile(p):
      if os.path.isfile(p + '.unused'):
        os.remove(p + '.unused')
      os.rename(p, p + '.unused')
    return subprocess.call("rsvars.bat & msbuild /t:Build /p:Config=" + config + " /p:Platform=Win32 \"" + project + "\"", shell=True) == 0

def buildProjects():
    for project in projects:
      res = buildProject(project)
      if not res:
        return False
    return True


def build_unit_tests():
    res = buildProject('unittests\\UnitTests.dproj', 'PLAINDUNITX')
    return res


def create_build_tag(version):
    global GlobalBuildVersion
    GlobalBuildVersion = version
    header("BUILD VERSION: " + GlobalBuildVersion)
    f = open("VERSION.TXT","w")
    f.write("VERSION " + GlobalBuildVersion + "\n")
    f.write("BUILD DATETIME " + datetime.now().isoformat() + "\n")
    f.close()

#############################################################################################################################

def task_build():
    '''Use: doit build -v <VERSION> -> Builds all the projects. Then creates SFX archive.'''    
    return {
        'actions': [
						create_build_tag,
						"echo %%date%% %%time:~0,8%% > LOGGERPRO-BUILD-TIMESTAMP.TXT",            
						buildProjects,
						build_unit_tests,
						"unittests\\Win32\\Release\\UnitTests.exe -exit:Continue"],
	'params':[{'name':'version',
	           'short':'v',
	           'long':'version',
             'type':str,
             'default':'DEVELOPMENT'}
             ],						
        'verbosity': 2
        }

def task_unittests():
    '''Use: doit unittests. Builds unittests project and run it.'''    
    return {
        'actions': [
					build_unit_tests,
					"unittests\\Win32\\Release\\UnitTests.exe -exit:Continue"
					],
				'params':[{'name':'version',
					'short':'v',
					'long':'version',
					'type':str,
					'default':'DEVELOPMENT'}
        ],
        'verbosity': 2
        }
				