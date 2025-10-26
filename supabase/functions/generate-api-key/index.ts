// Supabase Edge Function: generate-api-key
// Returns API keys for authenticated users
// Usage: POST /generate-api-key { "service": "Pollo" }

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get service from request body
    const { service } = await req.json()
    
    if (!service) {
      return new Response(
        JSON.stringify({ error: 'Missing service parameter' }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Authenticate user
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { 
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Verify user token
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { 
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // For local testing (127.0.0.1), check environment variables first
    const isLocal = req.headers.get('host')?.includes('127.0.0.1') || 
                    req.headers.get('host')?.includes('localhost')
    
    if (isLocal) {
      const envKey = Deno.env.get(`${service.toUpperCase()}_API_KEY`)
      if (envKey) {
        console.log(`🔧 Local mode: Returning ${service} key from environment`)
        return new Response(
          JSON.stringify({ key: envKey }),
          {
            status: 200,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          }
        )
      }
    }

    // Look up API key in database
    const { data, error } = await supabase
      .from('api_keys')
      .select('key')
      .eq('service', service)
      .single()

    if (error || !data) {
      return new Response(
        JSON.stringify({ error: 'Not found' }),
        { 
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Return the API key
    return new Response(
      JSON.stringify({ key: data.key }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error in generate-api-key:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

