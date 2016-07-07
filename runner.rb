require 'json'
require 'date'

def wrap_in_a_td(data)
  "<td>#{data}</td>"
end

def wrap_in_a_tr(data)
  "<tr>#{data}</tr>"
end

def wrap_in_a_table(data)
  "<table cellpadding='3'>#{data}</table>"
end

def anchor_tag(hash)
  name = hash['subject']
  url = "https://#{ENV["GERRITDOMAIN"]}/#/c/#{hash['_number']}/"
  "<a href='#{url}' target='_blank'>#{name}</a>"
end

def days_old_message(hash)
  date = hash['created'][0,10]
  (Date.today - Date.parse(date)).floor.to_s + " Days Old"
end

def transform_changeset_hash_to_html_tr(hash)
  wrap_in_a_tr(
    [
      wrap_in_a_td(days_old_message(hash)),
      wrap_in_a_td(hash["user_name"]),
      wrap_in_a_td(hash["project"]),
      wrap_in_a_td(anchor_tag(hash)),
    ].join('')
  )
end

def transform_array_to_table(changesets)
  wrap_in_a_table(
    changesets.map {|hash| transform_changeset_hash_to_html_tr(hash) }.join("\n")
  )
end

def build_html_file(html_table)
  [
    "<html>",
    "<body>",
    "<h1>Open Changesets for #{Date.today}</h1>",
    html_table,
    "</body>",
    "</html>"
  ].join("\n")
end

def build_curl_command_base
  [
    "curl --silent --digest --user",
    "#{ENV["GERRITUSER"]}:#{ENV["GERRITHTTPPASSWORD"]}",
    "https://#{ENV["GERRITDOMAIN"]}/a/"
  ].join(" ")
end

def build_curl_command_for_group_members(group_id)
  [
    build_curl_command_base,
    "groups/",
    group_id,
    "/members/"
  ].join("")
end

def build_curl_command_for_groups
  [
    build_curl_command_base,
    "groups/"
  ].join("")
end

def build_curl_command_for_changesets(project_name)
  [
    build_curl_command_base,
    "changes/\?q\=status:open+project:",
    project_name
  ].join("")
end

def execute(curl_command)
  `#{curl_command}`
end

def transform_json_to_array(raw_changeset_string)
  JSON.parse(
    raw_changeset_string.sub(")]}'", '')
  )
end

def sort_by_created(changesets)
  changesets.sort {|hash1, hash2| hash1['created'] <=> hash2['created']}
end

def add_user_name_to_change_sets!(sorted_change_sets, members_hash)
  sorted_change_sets.each do |change_set|
    account_id = change_set["owner"]["_account_id"]
    change_set["user_name"] = members_hash[account_id]
  end
end

def remove_nil_users(change_sets)
  change_sets.reject {|change_set| change_set["user_name"].nil? }
end

group_name = ARGV[1]

groups = transform_json_to_array(
  execute(
    build_curl_command_for_groups
  )
)

group_data = groups[group_name]

group_id = group_data["id"]

group_members = transform_json_to_array(
  execute(
    build_curl_command_for_group_members(
      group_id
    )
  )
)

members_hash = {}
group_members.each {|gm| members_hash[gm["_account_id"]] = gm["name"] }

project_names = ARGV[0].split(',')

change_sets = project_names.map do |project_name|
  transform_json_to_array(
    execute(
      build_curl_command_for_changesets(
        project_name
      )
    )
  )
end.flatten

sorted_change_sets = sort_by_created(change_sets)

add_user_name_to_change_sets!(sorted_change_sets, members_hash)

filtered_change_sets = remove_nil_users(sorted_change_sets)

html_contents = build_html_file(
  transform_array_to_table(
    filtered_change_sets
  )
)

File.open("open_changesets.html", "w") do |file_handle|
  file_handle.write(html_contents)
end

