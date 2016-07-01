require 'json'
require 'date'

def transform_changeset_hash_to_html_li(hash)
  date = hash['created'][0,10]

  [
    "<li>",
    "<a href='https://#{ENV["GERRITDOMAIN"]}/#/c/#{hash['_number']}/' target='_blank'>",
    (Date.today - Date.parse(date)).floor,
    " Days Old - ",
    hash['subject'],
    "</a>",
    "</li>"
  ].join('')
end

def build_curl_command
  [
    "curl --silent --digest --user",
    "#{ENV["GERRITUSER"]}:#{ENV["GERRITHTTPPASSWORD"]}",
    "https://#{ENV["GERRITDOMAIN"]}/a/changes/\?q\=status:open+project:#{ARGV[0]}"
  ].join(" ")
end

def execute(curl_command)
  `#{curl_command}`
end

def build_html_file(lines)
  [
    "<html>",
    "<body>",
    "<h1>Open Changesets</h1>",
    "<ul>",
    lines.join("\n"),
    "</ul>",
    "</body>",
    "</html>"
  ].join("\n")
end

def fetch_raw_changesets
  execute(
    build_curl_command
  )
end

def transform_json_to_array(raw_changeset_string)
  JSON.parse(
    raw_changeset_string.sub(")]}'", '')
  )
end

def transform_array_to_html(changesets)
  changesets.map {|hash| transform_changeset_hash_to_html_li(hash) }
end

def sort_by_created(changesets)
  changesets.sort {|hash1, hash2| hash1['created'] <=> hash2['created']}
end

File.open("open_changesets.html", "w") do |file_handle|
  file_handle.write(
    build_html_file(
      transform_array_to_html(
        sort_by_created(
          transform_json_to_array(
            fetch_raw_changesets
          )
        )
      )
    )
  )
end

