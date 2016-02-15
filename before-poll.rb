say 'Running mbsync...'
# system 'mbsync -a -q'
system 'mbsync -a 2>&1 | tee >(>>~/.sup/mbsynclog )'
#system "mbsync -a 2>&1 | awk '{ print strftime(), $0; fflush() }' >> /home/lsfxz/.sup/mbsyncsuplog.log"

maildr = "#{Dir.home}/Mail"
inboxdr = maildr + '/INBOX/new'
spamdr = maildr + '/Spam/new'
unsuredr = maildr + '/Unsure/new'

Dir.chdir(inboxdr)
Dir.new(Dir.pwd).each do |newmail|
  next if newmail == '..' || newmail == '.' || File.directory?(newmail)
  if system "bogofilter -l -I #{newmail}"
    FileUtils.mv(newmail, spamdr + "/#{newmail.gsub(/\,U=([0-9]){4,5}\:2,/,':2,S')}") ## unless File.exist? ?
    debug "moved #{newmail} to " + spamdr + "/#{newmail.gsub(/\,U=([0-9]){4,5}\:2,/,':2,S')}"
  elsif $?.exitstatus == 1
      ## Todo: add exceptions?
      ## nospam, yay \o/
  elsif $?.exitstatus == 2
    FileUtils.mv(newmail, unsuredr + "/#{newmail.gsub(/\,U=([0-9]){4,5}/,'')}")
    debug "moved #{newmail} to " + unsuredr + "/#{newmail.gsub(/\,U=([0-9]){4,5}/,'')}"
  else
    say 'bogofilter failed! (probably)'
  end
end
