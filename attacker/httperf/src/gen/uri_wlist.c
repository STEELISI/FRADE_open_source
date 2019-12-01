/*
    httperf -- a tool for measuring web server performance
    Copyright 2000-2007 Hewlett-Packard Company

    This file is part of httperf, a web server performance measurment
    tool.

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation; either version 2 of the
    License, or (at your option) any later version.
    
    In addition, as a special exception, the copyright holders give
    permission to link the code of this work with the OpenSSL project's
    "OpenSSL" library (or with modified versions of it that use the same
    license as the "OpenSSL" library), and distribute linked combinations
    including the two.  You must obey the GNU General Public License in
    all respects for all of the code used other than "OpenSSL".  If you
    modify this file, you may extend this exception to your version of the
    file, but you are not obligated to do so.  If you do not wish to do
    so, delete this exception statement from your version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  
    02110-1301, USA
*/

/* This load generator can be used to recreate a workload based on a
   server log file.
 
   The format of the file used by this module is very simple:

	URI1
	URI2
	...
	URIn
  
   This is based on uri_wlog module but it allows for a given source
   IP to go through the list in order from front to back, and then
   start from front again. For issues please contact sunshine@isi.edu */

#include "config.h"

#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>

#include <generic_types.h>

#include <object.h>
#include <timer.h>
#include <httperf.h>
#include <call.h>
#include <conn.h>
#include <core.h>
#include <localevent.h>


#define MAX_URI_LEN 128
#define MAX_URIS 128
#define MAX_IPS 5000

static char *fbase, *fend, *fcurrent;
static int num_uris=0;
static char* uris[MAX_URIS];
static int pos[MAX_IPS];

static void
set_uri (Event_Type et, Call *call)
{
  assert (et == EV_CALL_NEW && object_is_call (call));
  const char* uri;

  int ip = call->myip;
  assert( ip < MAX_IPS );
  int mypos = pos[ip]++;
  uri = uris[mypos % num_uris];
  int len = strlen(uri); 
  call_set_uri (call, uri, len);
}

/*
static void
set_uri (Event_Type et, Call * c)
{
  int len = 0;
  int i=0;
  const char *uri;

  assert (et == EV_CALL_NEW && object_is_call (c));
  printf("Calling set uri on c");

  do{
    int ip = 2345;//c->conn->myip;
    int pos = find(ip);
    if (pos == -1)
      {
	insert(ip);
	pos = 0;
      }
    
    uri = uris[pos % num_uris];
    len = strlen(uri);
    call_set_uri (c, uri, len);
  }while(len == 0);

  if (verbose)
    printf ("%s: URI `%s'\n", prog_name, uri);
}
*/

void
init_wlist (void)
{
  struct stat st;
  Any_Type arg;
  printf("\n Called init_wlist");
  FILE* fd = fopen(param.wlist.file, "r");
  if (fd == 0)
    panic ("%s: can't open %s\n", prog_name, param.wlist.file);

  /* save strings in an array */
  for (int i=0; i<MAX_URIS; i++)
    {
      uris[i] = (char*) malloc(MAX_URI_LEN);
    }
  for (int i=0; i<MAX_IPS; i++)
    {
      pos[i] = 0;
    }

  while(!feof(fd))
    {
      fscanf(fd, "%s", uris[num_uris++]);
    }
  fclose (fd);

  arg.l = 0;
  event_register_handler (EV_CALL_NEW, (Event_Handler) set_uri, arg);
}

static void
stop_wlist (void)
{
}

Load_Generator uri_wlist =
  {
    "Generates URIs based on a predetermined list",
    init_wlist,
    no_op,
    stop_wlist
  };
