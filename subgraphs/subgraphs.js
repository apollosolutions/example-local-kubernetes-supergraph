import { expressMiddleware } from '@as-integrations/express5';
import { ApolloServer } from '@apollo/server';
import { ApolloServerPluginDrainHttpServer } from '@apollo/server/plugin/drainHttpServer';
import { ApolloServerPluginUsageReportingDisabled } from '@apollo/server/plugin/disabled';
import express from 'express';
import http from 'http';
import cors from 'cors';
import bodyParser from 'body-parser';
import { WebSocketServer } from "ws";
import { useServer } from "graphql-ws/use/ws";
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
    subscriptions: true
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
  // Log pod ID for Kubernetes identification
  const podId = process.env.HOSTNAME || 'unknown';
  console.log(`🚀 [${podId}] Starting subgraphs server...`);
  
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

    const path = `/${subgraphConfig.name}/graphql`;

    let wsPlugin = {};
    if (subgraphConfig.subscriptions === true) {
      // Create WebSocket server for this subgraph
      const wsServer = new WebSocketServer({
        server: httpServer,
        path,
      });
      
      // Add WebSocket connection logging
      wsServer.on('connection', (socket, request) => {
        console.log(`🔌 [${podId}] WebSocket connection established for [${subgraphConfig.name}] subgraph`);
        console.log(`🔌 [${podId}] Client IP: ${request.socket.remoteAddress}`);
        
        socket.on('close', () => {
          console.log(`🔌 [${podId}] WebSocket connection closed for [${subgraphConfig.name}] subgraph`);
        });
        
        socket.on('error', (error) => {
          console.log(`❌ [${podId}] WebSocket error for [${subgraphConfig.name}] subgraph:`, error.message);
        });
      });
      
      const serverCleanup = useServer({ schema }, wsServer);
      wsPlugin = {
        async serverWillStart() {
          return {
            async drainServer() {
              await serverCleanup.dispose();
            },
          };
        },
      };
      console.log(`🚀 [${podId}] Setting up WebSocket server for [${subgraphConfig.name}] subgraph at ws://localhost:${serverPort}${path}`);
    }

    console.log(`🚀 [${podId}] Setting up HTTP server for [${subgraphConfig.name}] subgraph at http://localhost:${serverPort}${path}`);

    const server = new ApolloServer({
      schema,
      // For a real subgraph introspection should remain off, but for demo we enabled
      introspection: true,
      // Disable CSRF protection for Kubernetes deployment
      csrfPrevention: false,
      plugins: [
        ApolloServerPluginDrainHttpServer({ httpServer }),
        ApolloServerPluginUsageReportingDisabled(),
        wsPlugin
      ]
    });

    await server.start();

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
  }

  // Start entire monolith at given port
  await new Promise((resolve) => httpServer.listen({ port: serverPort }, resolve));
  console.log(`🚀 [${podId}] All subgraphs started and listening on port ${serverPort}`);
};
