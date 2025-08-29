import { USERS } from "./data.js";
import { GraphQLError } from "graphql";

const getUserById = (id) => USERS.find((it) => it.id === id);

export const resolvers = {
  Query: {
    user(_, { id }, context) {
      const user = getUserById(id);

      if (!user) {
        throw new GraphQLError(`Could not locate user by id: ${id}`);
      }

      return user;
    },
    allUsers() {
      return USERS;
    }
  },
  User: {
    __resolveReference(ref) {
      return getUserById(ref.id);
    },
    loyaltyPoints: () => Math.floor(Math.random() * 20)
  }
};
