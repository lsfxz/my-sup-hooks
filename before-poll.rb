say 'Running mbsync...'
# system 'mbsync -a -q'
system 'mbsync -a -q'
# system "mbsync -a 2>&1 | awk '{ print strftime(), $0; fflush() }' >> /home/lsfxz/.sup/mbsyncsuplog.log"

maildr = "#{Dir.home}/Mail"
#directly writing to new subfolders, because all this happens before the MUA (-> sup) polls — so tmp seems unneccessary
inboxdr = maildr + '/INBOX/new'
spamdr = maildr + '/Spam/cur'
unsuredr = maildr + '/Unsure/new'

def new_maildir_basefn #shamelessly ripped out of maildir.rb's guts...
  Kernel::srand()
  "#{Time.now.to_i.to_s}.#{$$}#{Kernel.rand(1000000)}.#{MYHOSTNAME}"
end

# new_fn = new_maildir_basefn + ':2,S'

Dir.chdir(inboxdr)
Dir.new(Dir.pwd).each do |newmail|
  next if newmail == '..' || newmail == '.' || File.directory?(newmail)
  if system "bogofilter -l -I #{newmail}"
    FileUtils.mv(newmail, spamdr + '/' + new_maildir_basefn + ':2,S') ## unless File.exist? ?
    debug "moved #{newmail} to " + spamdr + '/' + new_maildir_basefn + ':2,S'
  elsif $?.exitstatus == 1
    ## Todo: add exceptions?
    ## nospam, yay \o/
  elsif $?.exitstatus == 2
    FileUtils.mv(newmail, unsuredr + '/' + new_maildir_basefn)
    debug "moved #{newmail} to " + unsuredr + '/' + new_maildir_basefn
  else
    say 'bogofilter failed! (probably)'
  end
end
