import sys

current_tag = sys.argv[1]
remote_tags = sys.argv[2].split("\n")

current_tag_index = remote_tags.index(current_tag)
remote_tags_of_interest = remote_tags[current_tag_index:]

if len(remote_tags_of_interest) > 1:
    # -> newer tag found, so print it
    print(remote_tags_of_interest[-1])
