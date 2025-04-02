import { Router } from 'itty-router';
import { verify } from '@tsndr/cloudflare-worker-jwt';

// Types
interface Env {
  DB: D1Database;
  DOCUMENTS: R2Bucket;
  JWT_SECRET: string;
}

// Create router
const router = Router();

// Middleware for authentication
const authenticate = async (request: Request, env: Env) => {
  const token = request.headers.get('Authorization')?.split('Bearer ')[1];
  
  if (!token) {
    return new Response('Unauthorized', { status: 401 });
  }

  try {
    const isValid = await verify(token, env.JWT_SECRET);
    if (!isValid) {
      return new Response('Invalid token', { status: 401 });
    }
  } catch (error) {
    return new Response('Authentication failed', { status: 401 });
  }
};

// Routes
router
  .get('/api/health', () => new Response('OK'))
  
  // Client routes
  .get('/api/clients/:id', authenticate, async (request, env: Env) => {
    const { id } = request.params;
    const client = await env.DB
      .prepare('SELECT * FROM clients WHERE id = ?')
      .bind(id)
      .first();
    
    return new Response(JSON.stringify(client), {
      headers: { 'Content-Type': 'application/json' }
    });
  })
  
  // Loan routes
  .post('/api/loans', authenticate, async (request, env: Env) => {
    const { clientId, amount, termMonths, interestRate } = await request.json();
    const loanId = crypto.randomUUID();
    
    try {
      await env.DB.prepare(`
        INSERT INTO loans (id, client_id, amount, term_months, interest_rate, status)
        VALUES (?, ?, ?, ?, ?, ?)
      `).bind(loanId, clientId, amount, termMonths, interestRate, 'PENDING')
        .run();
      
      return new Response(JSON.stringify({ loanId }), {
        headers: { 'Content-Type': 'application/json' }
      });
    } catch (error) {
      return new Response(JSON.stringify({ error: 'Failed to create loan' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  })
  
  // Document routes
  .post('/api/documents/upload', authenticate, async (request, env: Env) => {
    try {
      const formData = await request.formData();
      const file = formData.get('file') as File;
      const clientId = formData.get('clientId') as string;
      const loanId = formData.get('loanId') as string;
      const documentType = formData.get('documentType') as string;
      
      const key = `clients/${clientId}/documents/${documentType}/${Date.now()}-${file.name}`;
      await env.DOCUMENTS.put(key, file);
      
      const docId = crypto.randomUUID();
      await env.DB.prepare(`
        INSERT INTO documents (id, client_id, loan_id, document_type, r2_key, filename, mime_type, size)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `).bind(
        docId,
        clientId,
        loanId,
        documentType,
        key,
        file.name,
        file.type,
        file.size
      ).run();
      
      return new Response(JSON.stringify({ documentId: docId }), {
        headers: { 'Content-Type': 'application/json' }
      });
    } catch (error) {
      return new Response(JSON.stringify({ error: 'Failed to upload document' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  })
  
  // Catch-all route
  .all('*', () => new Response('Not Found', { status: 404 }));

// Export default worker
export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    return router.handle(request, env, ctx);
  }
}; 