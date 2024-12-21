import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();
const RESERVATIONS_COLLECTION = "books_reservation";

// Check reservations every 2 hours
export const checkReservationStatuses = functions.pubsub
  .schedule("every 2 hours")
  .onRun(async () => {
    const batch = firestore.batch();
    const now = admin.firestore.Timestamp.now();

    try {
      // Check for overdue reservations
      const borrowedQuery = await firestore
        .collection(RESERVATIONS_COLLECTION)
        .where("status", "==", "borrowed")
        .get();

      borrowedQuery.docs.forEach((doc) => {
        const dueDate = doc.data().dueDate;
        if (now.seconds > dueDate.seconds) {
          batch.update(doc.ref, { status: "overdue" });
        }
      });

      // Check for expired reservations (24h after reservation)
      const reservedQuery = await firestore
        .collection(RESERVATIONS_COLLECTION)
        .where("status", "==", "reserved")
        .get();

      reservedQuery.docs.forEach((doc) => {
        const createdAt = doc.data().borrowedDate;
        const expiryTime = 24 * 60 * 60; // 24 hours in seconds
        if (now.seconds - createdAt.seconds > expiryTime) {
          batch.update(doc.ref, {
            status: "expired",
            updatedAt: now,
          });
        }
      });

      // Commit all updates
      await batch.commit();
      console.log("Successfully updated reservation statuses");
      return null;
    } catch (error) {
      console.error("Error updating reservation statuses:", error);
      throw new functions.https.HttpsError("internal", "Failed to update reservations");
    }
  });

// Optional: Function to clean up expired reservations
export const cleanupExpiredReservations = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    const batch = firestore.batch();
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    try {
      const expiredQuery = await firestore
        .collection(RESERVATIONS_COLLECTION)
        .where("status", "==", "expired")
        .where("updatedAt", "<", admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
        .get();

      expiredQuery.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`Cleaned up ${expiredQuery.size} expired reservations`);
      return null;
    } catch (error) {
      console.error("Error cleaning up expired reservations:", error);
      throw new functions.https.HttpsError("internal", "Failed to cleanup reservations");
    }
  });
