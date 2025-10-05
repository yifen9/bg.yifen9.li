// src/content.config.ts
import { defineCollection, z } from "astro:content";
import { glob } from "astro/loaders";

const blog = defineCollection({
	loader: glob({ base: "./src/content/blog", pattern: "**/*.md" }),
	schema: ({ image }) =>
		z.object({
			title: z.string(),
			date: z.string(),
			cover: image().optional(),
			players: z.array(z.string()).nonempty(),
			games: z
				.array(
					z
						.object({
							name: z.string(),
							session_id: z.string(),
							photo: z.string().optional(),
							participants: z.array(z.string()).nonempty(),
							ranks: z.array(z.number()).nonempty(),
							scores: z.array(z.number()).optional(),
							ratings: z.record(z.string(), z.number()).optional(),
						})
						.refine((v) => v.participants.length === v.ranks.length, {
							message: "participants and ranks length mismatch",
						}),
				)
				.nonempty(),
		}),
});

export const collections = { blog };
