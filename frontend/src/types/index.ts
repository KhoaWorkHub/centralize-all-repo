export interface Repository {
  id: number;
  name: string;
  fullName: string;
  description: string | null;
  htmlUrl: string;
  stargazersCount: number;
  forksCount: number;
  language: string | null;
  createdAt: string;
  updatedAt: string;
  isPrivate: boolean;
  isFork: boolean;
}

export interface RepositoryStats {
  totalRepositories: number;
  publicRepositories: number;
  privateRepositories: number;
  forkedRepositories: number;
  totalStars: number;
  totalForks: number;
}