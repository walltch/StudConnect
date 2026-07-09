export type Profile = {
  id: string;
  email: string;
  full_name: string;
  institution: string;
  filiere: string;
  annee_etude: string;
  skills: string[];
  reputation: number;
  avatar_url: string | null;
  created_at: string;
};

export type Post = {
  id: string;
  title: string;
  content: string;
  author_id: string;
  tags: string[];
  is_solved: boolean;
  accepted_comment_id: string | null;
  created_at: string;
  updated_at: string;
};

export type PostWithCounts = Post & {
  upvote_count: number;
  comment_count: number;
  author?: Profile;
};

export type Comment = {
  id: string;
  post_id: string;
  parent_comment_id: string | null;
  author_id: string;
  content: string;
  created_at: string;
  author?: Profile;
  upvote_count?: number;
  has_upvoted?: boolean;
  children?: Comment[];
};
