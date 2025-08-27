import { expressMiddleware } from '@as-integrations/express5';
import { ApolloServer } from '@apollo/server';
import { ApolloServerPluginDrainHttpServer } from '@apollo/server/plugin/drainHttpServer';
import { ApolloServerPluginUsageReportingDisabled } from '@apollo/server/plugin/disabled';
import express from 'express';
import http from 'http';
import cors from 'cors';
import bodyParser from 'body-parser';
import { getProductsSchema } from './products/subgraph.js';
import { getReviewsSchema } from './reviews/subgraph.js';
import { getUsersSchema } from './users/subgraph.js';
import { addMocksToSchema } from "@graphql-tools/mock";

export const LOCAL_SUBGRAPH_CONFIG = [
  {
    name: 'products',
    getSchema: getProductsSchema
  },
  {
    name: 'reviews',
    getSchema: getReviewsSchema,
  },
  {
    name: 'users',
    getSchema: getUsersSchema,
    mock: false
  }
];

const getLocalSubgraphConfig = (subgraphName) =>
  LOCAL_SUBGRAPH_CONFIG.find(it => it.name === subgraphName);

export const startSubgraphs = async (httpPort) => {
  // Create a monolith express app for all subgraphs
  const app = express();
  const httpServer = http.createServer(app);
  const serverPort = process.env.PORT ?? httpPort;

  // Add a simple health check endpoint
  app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
  });

  // Run each subgraph on the same http server, but at different paths
  for (const subgraph of LOCAL_SUBGRAPH_CONFIG) {
    const subgraphConfig = getLocalSubgraphConfig(subgraph.name);
    let schema;

    if (subgraphConfig.mock === true) {
      schema = addMocksToSchema({
        schema: subgraphConfig.getSchema()
      })
    } else {
      schema = subgraphConfig.getSchema();
    }

    const server = new ApolloServer({
      schema,
      // For a real subgraph introspection should remain off, but for demo we enabled
      introspection: true,
      // Disable CSRF protection for Kubernetes deployment
      csrfPrevention: false,
      plugins: [
        ApolloServerPluginDrainHttpServer({ httpServer }),
        ApolloServerPluginUsageReportingDisabled()
      ]
    });

    await server.start();

    const path = `/${subgraphConfig.name}/graphql`;
    app.use(
      path,
      cors(),
      bodyParser.json(),
      expressMiddleware(server, {
        context: async ({ req }) => {
          return { headers: req.headers };
        }
      })
    );

    console.log(`Setting up [${subgraphConfig.name}] subgraph at http://localhost:${serverPort}${path}`);
  }

  // Start entire monolith at given port
  await new Promise((resolve) => httpServer.listen({ port: serverPort }, resolve));
};
