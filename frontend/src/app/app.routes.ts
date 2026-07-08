import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./features/posts/posts-page.component').then((m) => m.PostsPageComponent),
  },
  {
    path: 'folders',
    loadComponent: () =>
      import('./features/folders/folders-page.component').then((m) => m.FoldersPageComponent),
  },
  {
    path: 'tags',
    loadComponent: () =>
      import('./features/tags/tags-page.component').then((m) => m.TagsPageComponent),
  },
  { path: '**', redirectTo: '' },
];
