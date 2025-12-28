const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onMemberCreated = functions.firestore
  .document("groups/{groupId}/members/{memberId}")
  .onCreate(async (_, context) => {
    const groupId = context.params.groupId;
    const groupRef = admin.firestore().doc(`groups/${groupId}`);

    await groupRef.update({
      members_count: admin.firestore.FieldValue.increment(1),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

exports.onMemberDeleted = functions.firestore
  .document("groups/{groupId}/members/{memberId}")
  .onDelete(async (_, context) => {
    const groupId = context.params.groupId;
    const groupRef = admin.firestore().doc(`groups/${groupId}`);

    await groupRef.update({
      members_count: admin.firestore.FieldValue.increment(-1),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
