import { useState, useEffect } from 'react';
import { Repository, RepositoryStats } from '../types';

const API_BASE_URL = process.env.REACT_APP_API_URL 
  ? `${process.env.REACT_APP_API_URL}/api`
  : process.env.NODE_ENV === 'production' 
    ? '/api' 
    : 'http://localhost:8080/api';

export const useRepositories = () => {
  const [repositories, setRepositories] = useState<Repository[]>([]);
  const [stats, setStats] = useState<RepositoryStats | null>(null);
  const [languages, setLanguages] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchRepositories = async (search?: string, language?: string) => {
    try {
      setLoading(true);
      setError(null);
      
      const params = new URLSearchParams();
      if (search) params.append('search', search);
      if (language) params.append('language', language);
      
      const response = await fetch(`${API_BASE_URL}/repos?${params.toString()}`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      setRepositories(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch repositories');
    } finally {
      setLoading(false);
    }
  };

  const fetchStats = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/repos/stats`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      setStats(data);
    } catch (err) {
      console.error('Failed to fetch stats:', err);
    }
  };

  const fetchLanguages = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/repos/languages`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      setLanguages(data);
    } catch (err) {
      console.error('Failed to fetch languages:', err);
    }
  };

  const refreshRepositories = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/repos/refresh`, {
        method: 'POST',
      });
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      setRepositories(data);
      await fetchStats();
      await fetchLanguages();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to refresh repositories');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRepositories();
    fetchStats();
    fetchLanguages();
  }, []);

  return {
    repositories,
    stats,
    languages,
    loading,
    error,
    fetchRepositories,
    refreshRepositories,
  };
};