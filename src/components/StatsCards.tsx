import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { RepositoryStats } from '../types';
import { formatNumber } from '../lib/utils';
import { GitFork, Star, Lock, Unlock, BookOpen, TrendingUp } from 'lucide-react';

interface StatsCardsProps {
  stats: RepositoryStats | null;
  loading: boolean;
}

export const StatsCards: React.FC<StatsCardsProps> = ({ stats, loading }) => {
  if (loading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
        {[...Array(6)].map((_, index) => (
          <Card key={index} className="animate-pulse">
            <CardHeader className="pb-2">
              <div className="h-4 bg-gray-200 rounded w-3/4"></div>
            </CardHeader>
            <CardContent>
              <div className="h-8 bg-gray-200 rounded w-1/2"></div>
            </CardContent>
          </Card>
        ))}
      </div>
    );
  }

  if (!stats) return null;

  const statItems = [
    {
      title: 'Total Repositories',
      value: stats.totalRepositories,
      icon: BookOpen,
      description: 'All repositories',
      color: 'text-blue-600',
    },
    {
      title: 'Public Repositories',
      value: stats.publicRepositories,
      icon: Unlock,
      description: 'Publicly accessible',
      color: 'text-green-600',
    },
    {
      title: 'Private Repositories',
      value: stats.privateRepositories,
      icon: Lock,
      description: 'Private access only',
      color: 'text-orange-600',
    },
    {
      title: 'Total Stars',
      value: stats.totalStars,
      icon: Star,
      description: 'Stars received',
      color: 'text-yellow-600',
    },
    {
      title: 'Total Forks',
      value: stats.totalForks,
      icon: GitFork,
      description: 'Times forked',
      color: 'text-purple-600',
    },
    {
      title: 'Forked Repositories',
      value: stats.forkedRepositories,
      icon: TrendingUp,
      description: 'Repositories forked by you',
      color: 'text-indigo-600',
    },
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
      {statItems.map((item) => {
        const Icon = item.icon;
        return (
          <Card key={item.title}>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {item.title}
              </CardTitle>
              <Icon className={`h-4 w-4 ${item.color}`} />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {formatNumber(item.value)}
              </div>
              <CardDescription className="text-xs text-muted-foreground">
                {item.description}
              </CardDescription>
            </CardContent>
          </Card>
        );
      })}
    </div>
  );
};