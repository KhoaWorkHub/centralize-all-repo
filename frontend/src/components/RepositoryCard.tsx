import React from 'react';
import { ExternalLink, Star, GitFork, Calendar } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Repository } from '../types';
import { formatDate, formatNumber } from '../lib/utils';

interface RepositoryCardProps {
  repository: Repository;
}

export const RepositoryCard: React.FC<RepositoryCardProps> = ({ repository }) => {
  const languageColors: { [key: string]: string } = {
    JavaScript: 'bg-yellow-400',
    TypeScript: 'bg-blue-600',
    Python: 'bg-green-600',
    Java: 'bg-orange-600',
    'C++': 'bg-pink-600',
    'C#': 'bg-purple-600',
    Ruby: 'bg-red-600',
    Go: 'bg-cyan-600',
    Rust: 'bg-orange-800',
    PHP: 'bg-indigo-600',
    Swift: 'bg-orange-500',
    Kotlin: 'bg-purple-700',
  };

  const getLanguageColor = (language: string | null) => {
    if (!language) return 'bg-gray-400';
    return languageColors[language] || 'bg-gray-400';
  };

  return (
    <Card className="h-full hover:shadow-lg transition-shadow duration-200">
      <CardHeader className="pb-3">
        <div className="flex items-start justify-between">
          <div className="flex-1 min-w-0">
            <CardTitle className="text-lg font-semibold truncate">
              {repository.name}
            </CardTitle>
            <CardDescription className="text-sm text-muted-foreground mt-1">
              {repository.fullName}
            </CardDescription>
          </div>
          <div className="flex items-center gap-1 ml-2">
            {repository.isPrivate && (
              <span className="px-2 py-1 text-xs bg-yellow-100 text-yellow-800 rounded-full">
                Private
              </span>
            )}
            {repository.isFork && (
              <span className="px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded-full">
                Fork
              </span>
            )}
          </div>
        </div>
      </CardHeader>
      
      <CardContent className="pt-0">
        <div className="space-y-4">
          {repository.description && (
            <p className="text-sm text-muted-foreground line-clamp-2">
              {repository.description}
            </p>
          )}
          
          <div className="flex items-center gap-4 text-sm text-muted-foreground">
            {repository.language && (
              <div className="flex items-center gap-1">
                <div
                  className={`w-3 h-3 rounded-full ${getLanguageColor(repository.language)}`}
                />
                <span>{repository.language}</span>
              </div>
            )}
            
            <div className="flex items-center gap-1">
              <Star className="w-4 h-4" />
              <span>{formatNumber(repository.stargazersCount)}</span>
            </div>
            
            <div className="flex items-center gap-1">
              <GitFork className="w-4 h-4" />
              <span>{formatNumber(repository.forksCount)}</span>
            </div>
          </div>
          
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-1 text-xs text-muted-foreground">
              <Calendar className="w-3 h-3" />
              <span>Updated {formatDate(repository.updatedAt)}</span>
            </div>
            
            <Button
              variant="outline"
              size="sm"
              asChild
            >
              <a
                href={repository.htmlUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-1"
              >
                <ExternalLink className="w-3 h-3" />
                View
              </a>
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};