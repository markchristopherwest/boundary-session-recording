#!/bin/sh

# helper-license.sh

# Change the contents of this output to get the environment variables
# of interest. The output must be valid JSON, with strings for both
# keys and values.
cat <<EOF
{
  "local_user": "$(echo $USER)"
}
EOF