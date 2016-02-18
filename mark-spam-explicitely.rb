# can probably easily be modified to not actually move any files on the disk -
# but I prefer it that way, since that way things are "sorted" when accessing
# my mail via other means (eg. webmail).

require 'fileutils'

def mark_and_move(msg, where, cmd)
  stored = false
  begin
    location = "#{msg.source.to_s.gsub('maildir:/', '/')}/#{msg.source_info}"
  rescue OutOfSyncSourceError => e # still nedeed? TODO
    log "warning numb1: #{e.message}\n while storing #{m.id} stored_status: #{stored}"
    log "location is #{location}, m is #{m}"
  end

  debug "message is at #{location}"
  debug "storing message at source: #{where}"
  stored = where.store_message(msg.date, msg.from.email) do |f|
    msg.each_raw_message_line { |l| f.puts l }
    debug "New Mail stored at: #{f::path}" #this might work with f.path. I'll try someday.
  end

  ## system "bogofilter -l #{cmd} -I #{location}"
  location = "#{msg.source.to_s.gsub('maildir:/', '/')}/#{msg.source_info}"  ##update location, necc? TODO
  system cmd + "#{location}"
  debug "executed #{cmd} #{location}"
  msgsource = msg.source
  debug "deleting message at source: #{msgsource}"
  location = "#{msg.source.to_s.gsub('maildir:/', '/')}/#{msg.source_info}"  ##update location, necc? TODO
  if stored
    log "Couldn't delete #{location}" unless FileUtils.remove_file(location, force=true)
    # force = true so it doesn't crash horribly.. but instead logs "couldn't delete"
    # log "Couldn't delete #{location}" unless FileUtils.remove_file(location) or FileUtils.remove_file(location.gsub('/new','/cur') or FileUtils.remove_file(location.gsub('/new','/tmp') )  #TODO cur/new? necessary?
  elsif !stored
    log "Message couldn't be copied successfully!"
  end
  PollManager.poll_from msgsource ## so deleted message can be removed from index
  PollManager.poll_from where ## so newly saved message can be added to index
  ## That's a shit-ton (metric) of polling when marking a thread with several
  ## messages.. can this be done elsewhere more directly? (in sup) instead?
  ## It's a remnant of my attempts to solve this with _only_ a hook
end


source_inbox_uri = "maildir:#{Dir.home}/Mail/INBOX"
source_spam_uri = "maildir:#{Dir.home}/Mail/Spam"
source_unsure_uri = "maildir:#{Dir.home}/Mail/Unsure"
source_inbox = SourceManager.source_for(source_inbox_uri) or fail 'source_inbox not found'
source_spam = SourceManager.source_for(source_spam_uri) or fail 'source_spam not found'


BufferManager.flash "Marking things as #{action}"

if action == :spam
  if message.source.to_s.include? source_inbox_uri
    debug "inboxtospam"
    command = 'bogofilter -l -Ns -I '
    mark_and_move(message, source_spam, command)
  elsif message.source.to_s.include? source_spam_uri
    debug "nothingtodoherespamtospam"
  elsif message.source.to_s.include? source_unsure_uri
    debug "unsuretospam"
    command = 'bogofilter -l -s -I '
    mark_and_move(message, source_spam, command)
  end
elsif action == :ham
  if message.source.to_s.include? source_inbox_uri
    debug "nothingtodohereinboxtoinbox"
  elsif message.source.to_s.include? source_spam_uri
    debug "spamtoinbox"
    command = 'bogofilter -l -Sn -I '
    mark_and_move(message, source_inbox, command)
  elsif message.source.to_s.include? source_unsure_uri
    debug "unsuretoinbox"
    command = 'bogofilter -l -n -I '
    mark_and_move(message, source_inbox, command)
  end
end
