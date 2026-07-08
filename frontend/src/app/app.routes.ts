import { Routes } from '@angular/router';
import { authGuard } from './core/auth/auth.guard';

export const routes: Routes = [
  {
    path: '',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./features/posts/posts-page.component').then((m) => m.PostsPageComponent),
  },
  {
    path: 'folders',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./features/folders/folders-page.component').then((m) => m.FoldersPageComponent),
  },
  {
    path: 'tags',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./features/tags/tags-page.component').then((m) => m.TagsPageComponent),
  },
  {
    path: 'login',
    loadComponent: () =>
      import('./features/auth/login-page.component').then((m) => m.LoginPageComponent),
  },
  {
    path: 'register',
    loadComponent: () =>
      import('./features/auth/register-page.component').then((m) => m.RegisterPageComponent),
  },
  {
    path: 'callback',
    loadComponent: () =>
      import('./features/auth/callback-page.component').then((m) => m.CallbackPageComponent),
  },
  { path: '**', redirectTo: '' },
];
