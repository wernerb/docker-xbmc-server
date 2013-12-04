/*
 *      Copyright (C) 2005-2012 Team XBMC
 *      http://www.xbmc.org
 *
 *  This Program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2, or (at your option)
 *  any later version.
 *
 *  This Program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with XBMC; see the file COPYING.  If not, see
 *  <http://www.gnu.org/licenses/>.
 *
 */

#include "system.h"
#include "settings/AppParamParser.h"
#include "settings/AdvancedSettings.h"
#include "GUIInfoManager.h"
#include "FileItem.h"
#include "Application.h"
#include "ApplicationMessenger.h"
#include "PlayListPlayer.h"
#include "utils/log.h"
#include "xbmc.h"
#ifdef _LINUX
#include <sys/resource.h>
#include <signal.h>
#endif
#if defined(TARGET_DARWIN_OSX)
  #include "Util.h"
  // SDL redefines main as SDL_main 
  #ifdef HAS_SDL
    #include <SDL/SDL.h>
  #endif
#endif
#ifdef HAS_LIRC
#include "input/linux/LIRC.h"
#endif
#include "XbmcContext.h"

int main(int argc, char* argv[])
{
  int m_ExitCode;

  // set up some xbmc specific relationships
  XBMC::Context context;

  //this can't be set from CAdvancedSettings::Initialize() because it will overwrite
  //the loglevel set with the --debug flag
  g_advancedSettings.m_logLevel     = LOG_LEVEL_DEBUG;
  g_advancedSettings.m_logLevelHint = LOG_LEVEL_DEBUG;
  CLog::SetLogLevel(g_advancedSettings.m_logLevel);

#ifdef _LINUX
  // Prevent child processes from becoming zombies on exit if not waited upon. See also Util::Command
  struct sigaction sa;
  memset(&sa, 0, sizeof(sa));

  sa.sa_flags = SA_NOCLDWAIT;
  sa.sa_handler = SIG_IGN;
  sigaction(SIGCHLD, &sa, NULL);
#endif
  setlocale(LC_NUMERIC, "C");
  g_advancedSettings.Initialize();

#ifndef _WIN32
  CAppParamParser appParamParser;
  appParamParser.Parse((const char **)argv, argc);
#endif

  if (!g_advancedSettings.Initialized())
  {
    g_advancedSettings.m_logLevel     = LOG_LEVEL_DEBUG;
    g_advancedSettings.m_logLevelHint = LOG_LEVEL_DEBUG;
    g_advancedSettings.Initialize();
  }

  if (!g_application.Create())
  {
    fprintf(stderr, "ERROR: Unable to create application. Exiting\n");
    return -1;
  }

  if (!g_application.Initialize())
  {
    fprintf(stderr, "ERROR: Unable to Initialize. Exiting\n");
    return -1;
  }

  CLog::Log(LOGNOTICE, "Running the application..." );

  unsigned int lastFrameTime = 0;
  unsigned int frameTime = 0;
  const unsigned int noRenderFrameTime = 15;  // Simulates ~66fps

  CLog::Log(LOGNOTICE, "Starting Video Library Scan..." );

  printf("XBMC Media Center %s\n", g_infoManager.GetVersion().c_str());
  printf("Copyright (C) 2005-2011 Team XBMC - http://www.xbmc.org\n\n");
  printf("Starting Video Library Scan\n\n");

  // Start scanning the Video Library for changes...
  g_application.StartVideoScan("");

  // Run xbmc
  while (!g_application.m_bStop)
  {
    //-----------------------------------------
    // Animate and render a frame
    //-----------------------------------------
    lastFrameTime = XbmcThreads::SystemClockMillis();
    g_application.Process();

    // Frame move the scene
    if (!g_application.m_bStop) g_application.FrameMove(true, false);

    // If scanning the Video Library has finished then ask XBMC to quit...
    if (!g_application.IsVideoScanning()) 
    {
       CApplicationMessenger::Get().Quit();
    } else {
      printf(".");

      frameTime = XbmcThreads::SystemClockMillis() - lastFrameTime;
      if(frameTime < noRenderFrameTime)
         Sleep(noRenderFrameTime - frameTime);
    }

  } // while (!m_bStop)

  CLog::Log(LOGNOTICE, "Finished Video Library Scan..." );

  m_ExitCode = g_application.m_ExitCode;

  g_application.Destroy();

  printf("\n\nFinished Video Library Scan...\n");

  return m_ExitCode;
}