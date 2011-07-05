#!/usr/bin/python
#
# batch-ctl.cgi Copyright 2011, Opin Kerfi hf. <http://www.ok.is/>
#               Copyright 2011, Bjarni R. Einarsson <http://bre.klaki.net/>
#
# This is a CGI script for managing batch jobs (basically, a GUI for cron).
#
# It lets you check the state of a job, browse the job's log or manually
# launch a job from the browser.
#
##############################################################################
#
import cgi, cgitb, os, subprocess, sys, time

CONFIG = '/var/www/ok-batch/config'
DEFAULTS = {
  'job': '',
  'password': 'password',
  'script': os.path.basename(sys.argv[0]),
  'batch_desc': 'Null batch, does nothing at all.',
  'batch_dir': '/tmp',
  'batch_cmd': '/bin/true',
  'batch_args': '',
  'batch_interval': '900',
  'company': 'Opin Kerfi',
  'action': 'Status',
  'message': '<i>Unknown</i>',
  'title': 'Hello',
  ############################################################################
  'template_page': """\
<html><head>
 <title>%(job)s - %(title)s (%(company)s : %(script)s)</title>
</head><body><a name=top></a>
 <div class=header>
  <h1>%(job)s - %(title)s</h1>
  <p class=desc>%(batch_desc)s</p>
  <form class=actions action='?job=%(job)s' method=POST>
   <input type=hidden name=job value='%(job)s'>
   Password: <input type=password name=password value='%(password)s'><br>
   <input type=submit name=action value='Status'>
   <input type=submit name=action value='View_Log'>
   <input type=submit name=action value='Clear_Log'>
   <input type=submit name=action value='Run'>
  </form>
 </div>
 <div class=action><hr>
  <h2>%(action)s</h2>
  <div class=message>%(message)s</div>
 </div>
 <p class=footer><hr>
  %(company)s - %(script)s - <a href="http://www.ok.is/">Open Source
  Lausn fr&aacute; Opnum Kerfum</a></i>
 </p><a name=bottom></a>
</body></html>
""",
  ############################################################################
  'template_status': """<table>
   <tr><th>Running?</th><td>%(running)s</td></tr>
   <tr><th>Last run:</th><td>%(last_run_rel)s <small>(=%(last_run_ts)s)</small></td></tr>
   <tr><th>Directory:</th><td>%(directory)s</td></tr>
   <tr><th>Command:</th><td>%(command)s</td></tr>
   <tr><th>Arguments:</th><td>%(arguments)s</td></tr>
   <tr><th>Interval:</th><td>%(interval)s</td></tr>
  </table>""",
}


def FormatInterval(interval):
  txt = []
  for c, i in (('w', 7*24*3600), ('d', 24*3600), ('h', 3600), ('m', 60)):
    if (interval > i):
      txt.append('%s%c' % (int(interval/i), c))
      interval %= i
  return ' '.join(txt or ['0m'])

def FileLines(fn):
  fd = open(fn, 'r')
  lines = fd.readlines()
  fd.close()
  return lines

def GetConfig(jobname, fn, defaults):
  cfg = {}
  cfg.update(defaults)

  section = 'global'
  for line in FileLines(fn):
    if line.startswith('['):
      section = line[1:].replace(']', '').strip()

    elif line.startswith('#') or (line.strip() == ''):
      pass

    elif section in (jobname, 'global'):
      key, val = line.strip().split('=', 1)
      val = val.strip()
      if val.startswith('@'):
        cfg[key.strip().lower()] = ''.join(FileLines(val[1:]))
      else:
        cfg[key.strip().lower()] = val

  return cfg


class Job(object):
  def __init__(self, config):
    self.config = config
    self.name = config['job']

  def IsRunning(self):
    return os.path.exists(self.LockDirName())

  def LockDirName(self):
    return '%s/%s.running' % (self.config['batch_dir'], self.name)

  def Cleanup(self):
    os.rmdir(self.LockDirName())

  def LogFileName(self):
    return '%s/%s.log' % (self.config['batch_dir'], self.name)

  def GetLogData(self):
    return ''.join(FileLines(self.LogFileName()))

  def LastRunTime(self):
    try:
      return os.stat(self.LogFileName()).st_mtime
    except:
      return 0

  def LastRunTimeRelative(self, ts=None, suffix=''):
    ts = ts or self.LastRunTime()
    if ts:
      return FormatInterval(int(time.time() - ts)) + suffix
    else:
      return 'never'

  def GetStatus(self):
    ts = self.LastRunTime()
    return {
      'running': (self.IsRunning() and 'Yes' or 'No'),
      'last_run_ts': ts,
      'last_run_rel': self.LastRunTimeRelative(ts=ts, suffix=' ago'),
      'directory': self.config['batch_dir'],
      'command': self.config['batch_cmd'],
      'arguments': self.config['batch_args'],
      'interval': FormatInterval(int(self.config['batch_interval'])),
    }

  def Run(self, force=False):
    if force or not self.IsRunning():
      os.chdir(self.config['batch_dir'])
      try:
        os.mkdir(self.LockDirName())
      except:
        if not force: return False

      logf = open(self.LogFileName(), 'a')
      logf.write('\n%s\n' % ('#' * 79))
      logf.flush()
      if os.fork() == 0: 
        if os.fork() != 0: os._exit(0)

        for fd in range(0, 100):
          try:
            if fd != logf.fileno(): os.close(fd)
          except:
            pass

        args = [self.config['batch_cmd']]
        args.extend(self.config['batch_args'].split(' '))
        subprocess.call(args, stdin=open('/dev/null', 'r'),
                              stdout=logf, stderr=logf)

        os.rmdir(self.LockDirName())
        os._exit(0)

      logf.close()
      time.sleep(1)
      return True
    else:
      return False

  def AutoRun(self):
    interval = int(self.config['batch_interval'])
    if interval < 60:
      return False
    elif (time.time()-interval) > self.LastRunTime():
      return self.Run()
    else:
      return False


def HtmlClean(string):
  return string.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')

def HtmlCleanDict(ddict):
  cdict = {}
  for k in ddict: cdict[k] = HtmlClean(str(ddict[k]))
  return cdict

def Render(variables, config, template):
  v = {}
  v.update(config)
  v.update(variables)
  return config.get(template, '%s') % v

def SendReply(variables, config, contenttype='text/html'):
  print 'Content-Type: %s' % contenttype
  print
  print Render(variables, config, 'template_page')


def SendStatus(form, config, title='Job status'):
  SendReply({
    'title': title,
    'action': 'Status',
    'message': Render(HtmlCleanDict(Job(config).GetStatus()),
                      config, 'template_status'),
  }, config)

def SendLogin(form, config):
  SendReply({
    'title': 'Please log in',
    'action': 'Access denied',
    'message': 'Access denied. Please log in.',
  }, config)

def SendJobLog(form, config):
  try:
    ll = Job(config).GetLogData()
    loglines = '<pre>%s</pre>' % HtmlClean(ll)
  except:
    loglines = '<ul><i>Log does not exist.</i></ul>'

  SendReply({
    'title': 'Job log',
    'action': 'Log file',
    'message': loglines,
  }, config)

def ClearJobLog(form, config):
  os.remove(Job(config).LogFileName())
  SendJobLog(form, config)

def RunJob(form, config):
  Job(config).Run(force=True)
  SendStatus(form, config, title='Started job')

def AutoRunJob(form, config):
  if Job(config).AutoRun():
    SendStatus(form, config, title='Running job')
  else:
    SendStatus(form, config, title='Job not due')


def Main():
  cgitb.enable()
  form = cgi.FieldStorage()

  job = form.getfirst('job', 'default')
  config = GetConfig(job, CONFIG, DEFAULTS)
  config['job'] = job

  action = form.getfirst('action', 'status').lower()
  if action == 'autorun':
    config['password'] = ''
  elif config['password'] != form.getfirst('password', ''):
    config['password'] = ''
    action = 'login'

  return {
    'autorun':  AutoRunJob,
    'login':    SendLogin,
    'run':      RunJob,
    'status':   SendStatus,
    'view_log': SendJobLog,
    'clear_log': ClearJobLog,
  }[action](form, config)

if __name__ == "__main__":
  Main()

