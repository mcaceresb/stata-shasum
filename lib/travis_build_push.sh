#!/bin/bash
# ssh-keygen -t rsa -b 4096 -C "mauricio.caceres.bravo@gmail.com" -f lib/id_rsa_travis_shasum -N ''
# travis encrypt-file lib/id_rsa_travis_shasum lib/id_rsa_travis_shasum.enc
# https://github.com/alrra/travis-scripts/blob/master/docs/github-deploy-keys.md
# https://docs.travis-ci.com/user/encrypting-files/

if [[ $TRAVIS_OS_NAME == 'osx' ]]; then
    REPO=`git config remote.origin.url`
    SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}

    git config user.name "Travis CI"
    git config user.email "$COMMIT_AUTHOR_EMAIL"

    echo "Adding OSX files."
    git checkout develop
    git branch -D osx
    git checkout -B osx
	cp build/*plugin lib/plugin/
    git add -f build/*osx*plugin
    git add -f lib/plugin/*osx*plugin

    echo "Committing OSX files."
    git commit -m "[Travis] Add plugin output for OSX build"

    openssl aes-256-cbc -K $encrypted_4ca9127173cc_key -iv $encrypted_4ca9127173cc_iv -in lib/id_rsa_travis_shasum.enc -out lib/id_rsa_travis_shasum -d

    chmod 600 lib/id_rsa_travis_shasum
    eval `ssh-agent -s`
    ssh-add lib/id_rsa_travis_shasum

    echo "Pushing OSX files."
    git push -f ${SSH_REPO} osx

    rm -f lib/id_rsa_travis_shasum

    echo "Done"
fi
