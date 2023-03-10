#!/bin/bash
set -x -e

# logout from any OpenShift cluster as the Kubernetes tests will deploy things there
if command -v oc &> /dev/null; then
    oc logout || true
fi

export VERSION=""
if [ -f work/newVersion ]; then
  VERSION=$(cat work/newVersion)
else 
  if [ $# -eq 0 ]
    then
      echo "Release version required, or 'work/newVersion' file"
      exit 1
  fi
  VERSION=$1
fi 

if [ -f work/branch ]; then
  BRANCH=$(cat work/branch)
else
  BRANCH="HEAD"
fi

if [ -z "${GRAALVM_HOME}" ]
  then
    echo "GRAALVM_HOME must be defined"
    exit 2
fi

echo "Preparing release ${VERSION} on branch ${BRANCH}"

echo "Cloning quarkus"
git clone git@github.com:quarkusio/quarkus.git work/quarkus

cd work/quarkus
git checkout ${BRANCH}
HASH=$(git rev-parse --verify $BRANCH)
echo "Last commit is ${HASH} - creating detached branch"
git checkout -b "r${VERSION}" "${HASH}"
echo "Update version to ${VERSION}"

./update-version.sh ${VERSION}

export MAVEN_OPTS="-Dmaven.repo.local=$(realpath ../repository)"

mvn \
  clean install \
  -Dmaven.repo.local=$(realpath ../repository) \
  -pl !integration-tests/gradle -pl !integration-tests/maven -pl !integration-tests/kubernetes/quarkus-standard-way -pl !integration-tests/kubernetes/maven-invoker-way  \
  -Prelease \
  -DskipTests -DskipITs \
  -Ddokka

echo "Enforcing releases"
mvn org.apache.maven.plugins:maven-enforcer-plugin:3.0.0-M3:enforce -Drules=requireReleaseVersion,requireReleaseDeps

echo "Alright, commit"
git commit -am "[RELEASE] - Bump version to ${VERSION}"
git tag "$VERSION"
echo "Pushing tag to origin"
git push origin "$VERSION"

cd ../.. || exit 2
