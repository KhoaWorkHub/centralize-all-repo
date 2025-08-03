import React, { useState } from 'react';
import { Search, RefreshCw, Filter } from 'lucide-react';
import { Input } from './ui/input';
import { Button } from './ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';

interface SearchAndFiltersProps {
  onSearch: (searchTerm: string) => void;
  onLanguageFilter: (language: string) => void;
  onRefresh: () => void;
  languages: string[];
  loading: boolean;
  selectedLanguage: string;
}

export const SearchAndFilters: React.FC<SearchAndFiltersProps> = ({
  onSearch,
  onLanguageFilter,
  onRefresh,
  languages,
  loading,
  selectedLanguage,
}) => {
  const [searchTerm, setSearchTerm] = useState('');

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSearch(searchTerm);
  };

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setSearchTerm(value);
    
    // Debounced search - search as user types
    const timeoutId = setTimeout(() => {
      onSearch(value);
    }, 300);
    
    return () => clearTimeout(timeoutId);
  };

  const handleLanguageChange = (value: string) => {
    const language = value === 'all' ? '' : value;
    onLanguageFilter(language);
  };

  const handleClearFilters = () => {
    setSearchTerm('');
    onSearch('');
    onLanguageFilter('');
  };

  return (
    <div className="space-y-4 mb-6">
      <div className="flex flex-col sm:flex-row gap-4">
        {/* Search Input */}
        <form onSubmit={handleSearchSubmit} className="flex-1">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
            <Input
              type="text"
              placeholder="Search repositories by name or description..."
              value={searchTerm}
              onChange={handleSearchChange}
              className="pl-10 pr-4"
            />
          </div>
        </form>

        {/* Language Filter */}
        <div className="flex gap-2">
          <Select value={selectedLanguage || 'all'} onValueChange={handleLanguageChange}>
            <SelectTrigger className="w-[150px]">
              <Filter className="h-4 w-4 mr-2" />
              <SelectValue placeholder="Language" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Languages</SelectItem>
              {languages.map((language) => (
                <SelectItem key={language} value={language}>
                  {language}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>

          {/* Refresh Button */}
          <Button
            variant="outline"
            onClick={onRefresh}
            disabled={loading}
            className="shrink-0"
          >
            <RefreshCw className={`h-4 w-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
        </div>
      </div>

      {/* Active Filters Display */}
      {(searchTerm || selectedLanguage) && (
        <div className="flex items-center gap-2 text-sm">
          <span className="text-muted-foreground">Active filters:</span>
          {searchTerm && (
            <span className="px-2 py-1 bg-blue-100 text-blue-800 rounded-full text-xs">
              Search: "{searchTerm}"
            </span>
          )}
          {selectedLanguage && (
            <span className="px-2 py-1 bg-green-100 text-green-800 rounded-full text-xs">
              Language: {selectedLanguage}
            </span>
          )}
          <Button
            variant="ghost"
            size="sm"
            onClick={handleClearFilters}
            className="h-6 px-2 text-xs"
          >
            Clear all
          </Button>
        </div>
      )}
    </div>
  );
};