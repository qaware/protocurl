#!/bin/bash
set -e

# Concatenate the dev dockerfile and the final release dockerfile to get the combined one
cat dev/builder.local.Dockerfile release/final.Dockerfile >dev/generated.local.Dockerfile

# We want to be able to use certain GNU utilities in the tests. Hence, we add them
# here in the test image only.
sed -i "s|# MARKER-FOR-TESTS|COPY --from=builder /bin/* /bin/|" \
  dev/generated.local.Dockerfile
