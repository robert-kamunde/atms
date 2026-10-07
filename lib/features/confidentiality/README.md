# confidentiality (spec 4.8)
Enforced by Firestore and Storage Security Rules on the server, never by the app. The client only shows the Confidential option to users with confidential access and treats permission-denied exactly like not-found (see `lib/core/errors`). Sprint 5.
