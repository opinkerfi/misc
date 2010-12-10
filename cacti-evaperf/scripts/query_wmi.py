#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
import getopt
import os
import time
import pickle
import pprint
from subprocess import Popen,PIPE,STDOUT
hostname="commandview"
credential="/etc/cacti/cactiwmi.pw"
# This sets debugmode to true
debugmode=True
logfile="/var/log/cacti/query_eva.log"
tmp_dir="/var/tmp/cacti/" # Cache files go here
# Max cache size
CACHE_MAX_AGE=50 # How old (in seconds) can be. 60 seconds should be sufficient


def output( message ):
  debug( "Output: " +message )
  print message
  return 0

def error( message ):
  output( "ERROR: " + message )
  sys.exit(1)

def debug( message ):
  if debugmode == True:
    try:
      fileHandle = open(logfile,'a')
      fileHandle.write( "debug: " + message + '\n' )
      fileHandle.close()
    except IOError:
      print "ERROR: Could not write to logfile %s" % (logfile)
      sys.exit(1)

debug ( 'Input: ' + ' '.join( sys.argv ) )


class DataSet:
  """
How to create this dataset
 ds = Dataset(headers,row)

where headers are in the form:
 header1|header2|header3

and rows are in the form:
 row1col1|row1col2|row1col3
 row2col1|row2col2|row2col3

How to use this dataset:
 myobject = ds.getByName(r'OK-REKSTUR:101Z:Linux\Xenserver1')
 print myobject['Name']

  """
  headers = None
  rows = None
  objects = {}
  def __init__(self,headers,rows):
    self.headers = headers.strip().split('|')
    self.rows = rows
    for row in self.rows:
      currentObject = {}
      tmp = row.strip().split('|')
      if len(tmp) != len(self.headers): continue # this skips an empty line at the bottom
      for i in range(len(tmp)):
	# Special case scenario. If Name contains a backslash, translate it to forward slash
	if self.headers[i] == 'Name':
	  tmp[i] = tmp[i].replace('\\', '/')
	  tmp[i] = tmp[i].replace('(','[')
	  tmp[i] = tmp[i].replace(')',']')
	  # Also add a friendly name to the bunch
	  currentObject[ 'friendlyname' ] = self.getFriendlyName( tmp[i] )
	currentObject[ self.headers[i] ] = tmp[i]
      self.objects[ currentObject['Name'] ] = currentObject
    return None
  def getFriendlyName(self, name):
    "Changes the clumbersome FOLDER/VDISKNAME:HOSTPORT (EVA SYSTEM) to something shorter"
    #friendlyname = name.replace('.*/','')
    tmp = name.split('/')
    friendlyname = tmp.pop()
    tmp = friendlyname.split(' [')
    friendlyname = tmp.pop(0)
    return friendlyname
    
  def getByName(self, objectname):
    "Returns a dictionary that corresponds to one row of WMI output"
    try:
      return self.objects[objectname]
    except KeyError:
      error( "KeyError, object '%s' not found in wmi query"%(objectname))
  def index(self):
    "Returns a nice list of the Name of every object" 
    for key,value in self.objects.items():
      output( key )
    #return results
  def get(self, objectname, fieldname):
    """
      Returns a single value from a single object
      example: ds.get('VirtualDisk1', 'QueueDepth')
      returns: 0
    """
    if fieldname == 'Name':
      output( "0" )
      return 0
    currObject = self.getByName(objectname)
    try:
      output ( currObject[fieldname] )
    except KeyError:
      error( "KeyError, class '%s' does not have field called '%s'"%(self.objectname,fieldname))
  def query(self, fieldname):
    """
      Returns a list that corresponds to one column of WMI output
      Its supposed to look like this:
      Name1|fieldname1
      Name2|fieldname2
    """
    results = []
    for key,value in self.objects.items():
      #print value
      output ( "%s|%s" % (key, value[fieldname] ) )
    return results
  

"""
call_wmi()

Takes in: objectname, hostname, credentialfile
Returns: a DataSet
"""
def call_wmi(objectname,host=hostname,credentialfile=credential):
  command = "/usr/local/bin/wmic --authentication-file=%s //%s 'select * from %s'" % (credentialfile, host, objectname)
  if not os.path.exists(credentialfile):
    error( "Could not open authentication file '%s': No Such File or Directory"%credentialfile) 
  debug('debug: Executing command: %s'%command)
  p = Popen(command, shell=True,stdin=PIPE,stdout=PIPE,stderr=STDOUT, close_fds=True)
  (inp,output) = (p.stdin, p.stdout)
  output = output.read()
  return output

def wmi_output_to_dataset(objectname,wmi_output):
  "Takes the output of WMI (a string) as an input. Returns a DataSet"
  wmi_output = wmi_output.split('\n')
  if len(wmi_output) < 2:
    error( "We got no output from wmic command" )
  firstline = wmi_output[0]
  expected_firstline = 'CLASS: %s' % ( objectname )
  if  firstline.lower() != expected_firstline.lower():
    #print "Something is wrong!, this is the output"
    debug( "Invalid response from wmic command:" )
    debug( "----" )
    for line in wmi_output: debug(line)
    debug( "----" )
    error("Invalid response from wmic command")
  else:
    #print "Everything is beautiful"
    wmi_output.pop(0)
    headers=wmi_output.pop(0)
    rows=[]
    for line in wmi_output:
      rows.append(line)
  ds = DataSet(headers,rows)
  ds.objectname = objectname
  return ds

def updateCache(cachefile,objectname,hostname,credential):
  "Executes call_wmi() and updates cachefile accordingly"
  wmi_output = call_wmi(objectname,hostname,credential)
  try:
    if not os.path.exists(tmp_dir):
      os.mkdir(tmp_dir)
      os.chmod(tmp_dir,0777)
    if not os.path.exists(cachefile):
      fileHandle = open(cachefile,'w')
      os.chmod(cachefile,0777)
    else:
      fileHandle = open(cachefile,'w')
    fileHandle.write(wmi_output)
    fileHandle.close()
  except IOError, v:
    error( "Failed to write to cachefile '%s': %s" % (cachefile,v[1]) )

def getData(objectname,hostname,credential):
  cachefile = tmp_dir + "/cacti-" + hostname + "-" + objectname + ".cache"
  if not os.path.exists(cachefile):
    updateCache(cachefile,objectname,hostname,credential)
  else:
    age_of_cachefile = time.time() - os.path.getmtime(cachefile)
    if age_of_cachefile > CACHE_MAX_AGE:
      updateCache(cachefile,objectname,hostname,credential)
  try:
    fileHandle = open(cachefile, 'r')
    wmi_output = fileHandle.read()
    ds = wmi_output_to_dataset(objectname, wmi_output)
  except IOError, v :
    error( "Failed to read from file '%s': %s " % (cachefile, v[1]) )
  return ds


def displayHelp():
  helpString = '''
usage: %s [options] --host <HOST> -w <WMI_CLASS> <index|query|get> [attribute]
OPTIONS:
   --host <HOST>                   Connect to specific hostname
   --authentication-file FILE	   Path to credential file (default: /etc/cacti/<HOST>.pw)
   --class <WMI_CLASS>             Name of WMI_CLASS (default Win32_ComputerSystem)
   --help                          Display this helpString

EXAMPLES:
%s --host kleopatra --class Win32_ComputerSystem index
%s --host kleopatra --class Win32_PerfRawData_EVAPMEXT_HPEVAHostConnection query Name
%s --host kleopatra --class Win32_PerfRawData_EVAPMEXT_HPEVAVirtualDisk get WriteLatencyUs
''' % (sys.argv[0],sys.argv[0],sys.argv[0],sys.argv[0])
  print helpString

class Query:
  def __init__(self):
    self.hostname = None
    self.credential = None
    self.objectname = None
    self.method = None
    self.argument = None
    self.key = None
    pass
  def processArguments(self):
    arguments=[]
    for i in sys.argv:
      arguments.append( i )
    arguments.pop(0)
    if len(arguments) == 0:
      displayHelp()
      error ( 'No parameters given' )      
    while len(arguments) > 0:
      argument = arguments.pop(0).strip()
      if argument == '--help':
	displayHelp()
	sys.exit(0)
      elif argument == '--host':
	try:
	  self.hostname = arguments.pop(0)
	except IndexError:
	  pass
      elif argument == '--class':
	try:
	  self.objectname = arguments.pop(0)
	except IndexError:
	  pass
      elif argument == '--authentication-file':
	try:
	  self.credential = arguments.pop(0)
	except IndexError:
	  pass
      elif argument == 'query':
	self.method = argument
	try:
	  self.attribute = arguments.pop(0)
	except IndexError:
	  pass
      elif argument == 'get':
	self.method = argument
	self.attribute = arguments.pop(0)
	self.key = ' '.join( arguments )
	arguments = []
      elif argument == 'index':
	self.method = argument
      else:
	displayHelp()
	error( 'unknown option %s' % (argument) )
    # Assign self.credential a default value if none is given
    if not self.hostname:
      displayHelp()
      error( 'No Hostname given' )
    if not self.objectname:
      displayHelp()
      error( 'No Class given')
    if not self.method:
      displayHelp()
      error( 'No Method given' )
    if self.credential == None:
      self.credential = '/etc/cacti/%s.pw' % self.hostname
  def getData(self):
    self.ds = getData(self.objectname,self.hostname,self.credential)
    return self.ds
def main():
  query = Query()
  query.processArguments()
  ds = query.getData()
  # Check what to do with the object (index,get,query, etc)
  if query.method == 'index':
    ds.index()
  if query.method == 'get':
    ds.get( fieldname=query.attribute , objectname=query.key)
  if query.method == 'query':
    # Should print results in the format Name|attribute
    ds.query(query.attribute)
    
	
	
	
if __name__ == "__main__":
  main()
  #except:
  #  error( "Unexpected error: %s" % (sys.exc_info()[0]) )
