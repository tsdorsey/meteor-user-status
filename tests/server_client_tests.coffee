###
  Manual tests to do:

  logged out -> logged in
  logged in -> logged out
  logged in -> close session -> reopen
  logged in -> connection timeout
###

if Meteor.isServer
  # Publish status to client
  Meteor.publish null, -> Meteor.users.find {},
    fields: { status: 1 }

  Meteor.methods
    "grabStatus": ->
      Meteor.users.find({_id: $ne: TEST_userId}, { fields: { status: 1 }}).fetch()
    "grabSessions": ->
      UserStatus.connections.find({userId: $ne: TEST_userId}).fetch()

if Meteor.isClient
  Tinytest.addAsync "status - login", (test, next) ->
    InsecureLogin.ready ->
      test.ok()
      next()

  # Check that initialization is empty
  Tinytest.addAsync "status - online recorded on server", (test, next) ->
    Meteor.call "grabStatus", (err, res) ->
      test.isUndefined err
      test.length res, 1

      user = res[0]
      test.equal user._id, Meteor.userId()
      test.equal user.status.online, true
      test.isFalse(user.status.lastLogin is undefined)
      next()

  Tinytest.addAsync "status - session recorded on server", (test, next) ->
    Meteor.call "grabSessions", (err, res) ->
      test.isUndefined err
      test.length res, 1

      doc = res[0]
      test.equal doc.userId, Meteor.userId()
      test.isTrue doc.ipAddr?
      test.isTrue doc.loginTime?
      next()

  Tinytest.addAsync "status - online recorded on client", (test, next) ->
    test.equal Meteor.user().status.online, true
    next()

  Tinytest.addAsync "status - logout", (test, next) ->
    Meteor.logout (err) ->
      test.isUndefined err
      next()

  Tinytest.addAsync "status - offline recorded on server", (test, next) ->
    Meteor.call "grabStatus", (err, res) ->
      test.isUndefined err
      test.length res, 1

      user = res[0]
      test.isTrue user._id?
      test.equal user.status.online, false
      # logintime is still maintained
      test.isTrue user.status.lastLogin?
      next()

  Tinytest.addAsync "status - session userId deleted on server", (test, next) ->
    Meteor.call "grabSessions", (err, res) ->
      test.isUndefined err
      test.length res, 1

      doc = res[0]
      test.isFalse doc.userId?
      test.isTrue doc.ipAddr?
      test.isFalse doc.loginTime?

      next()
