import { REVIEWS } from "./data.js";

export const getReviewsById = (reviewId) =>
  REVIEWS.find((it) => it.id === reviewId);
export const getReviewsByProductUpc = (productUpc) =>
  REVIEWS.filter((it) => it.product.upc === productUpc);

export const resolvers = {
  Review: {
    __resolveReference: (ref) => getReviewsById(ref.id)
  },
  Product: {
    reviews: (parent) => getReviewsByProductUpc(parent.upc)
  },
  Subscription: {
    reviewAdded: {
      subscribe: async function* () {
        // Log the pod ID when subscription starts
        const podId = process.env.HOSTNAME || 'unknown';
        console.log(`🚀 [${podId}] Reviews subscription connection established`);
        
        let count = 0;
        while (true) {
          const review = REVIEWS[count++];
          console.log(`📤 [${podId}] Sending review: ${review.id} - ${review.title}`);
          yield { reviewAdded: review };
          await new Promise((resolve) => setTimeout(resolve, 3000));
          if (count === REVIEWS.length) count = 0;
        }
      },
    },
  },
};
