import React, { useState, useEffect } from 'react';
import { Github, AlertCircle } from 'lucide-react';
import { RepositoryCard } from './components/RepositoryCard';
import { StatsCards } from './components/StatsCards';
import { SearchAndFilters } from './components/SearchAndFilters';
import { useRepositories } from './hooks/useRepositories';
import { Repository } from './types';

function App() {
  const {
    repositories,
    stats,
    languages,
    loading,
    error,
    fetchRepositories,
    refreshRepositories,
  } = useRepositories();

  const [filteredRepositories, setFilteredRepositories] = useState<Repository[]>([]);
  const [currentSearch, setCurrentSearch] = useState('');
  const [currentLanguage, setCurrentLanguage] = useState('');

  useEffect(() => {
    setFilteredRepositories(repositories);
  }, [repositories]);

  const handleSearch = async (searchTerm: string) => {
    setCurrentSearch(searchTerm);
    if (searchTerm.trim() === '' && currentLanguage === '') {
      setFilteredRepositories(repositories);
    } else {
      await fetchRepositories(searchTerm, currentLanguage);
    }
  };

  const handleLanguageFilter = async (language: string) => {
    setCurrentLanguage(language);
    if (language === '' && currentSearch === '') {
      setFilteredRepositories(repositories);
    } else {
      await fetchRepositories(currentSearch, language);
    }
  };

  const handleRefresh = async () => {
    await refreshRepositories();
    setCurrentSearch('');
    setCurrentLanguage('');
  };

  if (error) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-center space-y-4">
          <AlertCircle className="h-12 w-12 text-destructive mx-auto" />
          <h1 className="text-2xl font-bold text-foreground">Error Loading Repositories</h1>
          <p className="text-muted-foreground max-w-md">
            {error}
          </p>
          <p className="text-sm text-muted-foreground">
            Make sure your GitHub Personal Access Token is configured in the backend.
          </p>
          <button
            onClick={() => window.location.reload()}
            className="px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b">
        <div className="container mx-auto px-4 py-6">
          <div className="flex items-center gap-3">
            <Github className="h-8 w-8 text-primary" />
            <div>
              <h1 className="text-3xl font-bold text-foreground">
                GitHub Repository Dashboard
              </h1>
              <p className="text-muted-foreground">
                Centralized view of all your repositories with real-time updates
              </p>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        {/* Stats Cards */}
        <StatsCards stats={stats} loading={loading} />

        {/* Search and Filters */}
        <SearchAndFilters
          onSearch={handleSearch}
          onLanguageFilter={handleLanguageFilter}
          onRefresh={handleRefresh}
          languages={languages}
          loading={loading}
          selectedLanguage={currentLanguage}
        />

        {/* Repository Grid */}
        {loading && filteredRepositories.length === 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[...Array(6)].map((_, index) => (
              <div key={index} className="animate-pulse">
                <div className="h-64 bg-gray-200 rounded-lg"></div>
              </div>
            ))}
          </div>
        ) : filteredRepositories.length === 0 ? (
          <div className="text-center py-12">
            <Github className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
            <h3 className="text-lg font-medium text-foreground mb-2">
              No repositories found
            </h3>
            <p className="text-muted-foreground">
              {currentSearch || currentLanguage
                ? 'Try adjusting your search criteria or filters.'
                : 'No repositories available. Make sure your GitHub token is configured properly.'}
            </p>
          </div>
        ) : (
          <>
            <div className="flex items-center justify-between mb-4">
              <p className="text-sm text-muted-foreground">
                Showing {filteredRepositories.length} repositories
                {(currentSearch || currentLanguage) && ' (filtered)'}
              </p>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {filteredRepositories.map((repository) => (
                <RepositoryCard key={repository.id} repository={repository} />
              ))}
            </div>
          </>
        )}
      </main>

      {/* Footer */}
      <footer className="border-t mt-12">
        <div className="container mx-auto px-4 py-6">
          <div className="text-center text-sm text-muted-foreground">
            <p>
              Built with ❤️ using React, TypeScript, Tailwind CSS, and Spring Boot
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}

export default App;