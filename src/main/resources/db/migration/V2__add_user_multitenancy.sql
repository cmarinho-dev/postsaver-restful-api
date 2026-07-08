-- Posts, folders and tags now belong to a user. No production data exists yet,
-- so the FK columns go straight to NOT NULL without a backfill step.

ALTER TABLE tb_post ADD COLUMN user_id BIGINT NOT NULL;
ALTER TABLE tb_post ADD CONSTRAINT fk_post_user FOREIGN KEY (user_id) REFERENCES tb_user (id);

ALTER TABLE tb_folder ADD COLUMN user_id BIGINT NOT NULL;
ALTER TABLE tb_folder ADD CONSTRAINT fk_folder_user FOREIGN KEY (user_id) REFERENCES tb_user (id);
ALTER TABLE tb_folder DROP CONSTRAINT uk_folder_name;
ALTER TABLE tb_folder ADD CONSTRAINT uk_folder_user_name UNIQUE (user_id, name);

ALTER TABLE tb_tag ADD COLUMN user_id BIGINT NOT NULL;
ALTER TABLE tb_tag ADD CONSTRAINT fk_tag_user FOREIGN KEY (user_id) REFERENCES tb_user (id);
ALTER TABLE tb_tag DROP CONSTRAINT uk_tag_name;
ALTER TABLE tb_tag ADD CONSTRAINT uk_tag_user_name UNIQUE (user_id, name);
